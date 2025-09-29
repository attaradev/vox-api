#!/usr/bin/env python3
import copy
import json
import os
import sys
import time

import boto3


def main():
    cluster = os.environ["ECS_CLUSTER"]
    region = os.environ["AWS_REGION"]
    family = os.environ["TASK_DEFINITION"]
    container_name = os.environ["CONTAINER_NAME"]
    subnets = json.loads(os.environ["SUBNETS_JSON"])
    service_sg = os.environ["SERVICE_SG"]

    if not subnets:
        print("No private subnets provided for migration task", file=sys.stderr)
        sys.exit(1)

    ecs = boto3.client("ecs", region_name=region)

    # Get latest task definition for the service family
    list_resp = ecs.list_task_definitions(
        familyPrefix=family, sort="DESC", maxResults=1
    )
    if not list_resp["taskDefinitionArns"]:
        print(f"No task definitions found for family {family}", file=sys.stderr)
        sys.exit(1)
    base_td_arn = list_resp["taskDefinitionArns"][0]
    base_td = ecs.describe_task_definition(taskDefinition=base_td_arn)["taskDefinition"]

    # Clone container definition for migrations
    api_container = next(
        (c for c in base_td["containerDefinitions"] if c["name"] == container_name),
        None,
    )
    if api_container is None:
        print(
            f"Container {container_name} not found in task definition {base_td_arn}",
            file=sys.stderr,
        )
        sys.exit(1)

    migrate_container = copy.deepcopy(api_container)
    migrate_container["command"] = ["python", "manage.py", "migrate", "--noinput"]
    # Ensure migrations run in entrypoint
    existing_env = {
        env["name"]: env["value"] for env in migrate_container.get("environment", [])
    }
    existing_env.update(
        {
            "RUN_DB_MIGRATIONS": "1",
            "SKIP_DB_MIGRATIONS": "0",
            "SERVICE_ROLE": "migrate",
        }
    )
    migrate_container["environment"] = [
        {"name": k, "value": v} for k, v in existing_env.items()
    ]

    # Update log stream prefix for clarity
    log_cfg = migrate_container.get("logConfiguration", {})
    if log_cfg.get("logDriver") == "awslogs":
        options = log_cfg.setdefault("options", {})
        options["awslogs-stream-prefix"] = "migrate"

    migrate_td_arn = base_td_arn

    try:
        run_resp = ecs.run_task(
            cluster=cluster,
            launchType="FARGATE",
            taskDefinition=migrate_td_arn,
            count=1,
            overrides={
                "containerOverrides": [
                    {
                        "name": container_name,
                        "command": ["python", "manage.py", "migrate", "--noinput"],
                        "environment": [
                            {"name": k, "value": v} for k, v in existing_env.items()
                        ],
                    }
                ]
            },
            networkConfiguration={
                "awsvpcConfiguration": {
                    "subnets": subnets,
                    "securityGroups": [service_sg],
                    "assignPublicIp": "DISABLED",
                }
            },
        )

        failures = run_resp.get("failures", [])
        if failures:
            print(
                "Failed to start migration task, failures:", failures, file=sys.stderr
            )
            sys.exit(1)

        tasks = run_resp.get("tasks", [])
        if not tasks:
            print("Failed to start migration task (no tasks returned)", file=sys.stderr)
            sys.exit(1)

        task_arn = tasks[0]["taskArn"]
        print(f"Started migration task: {task_arn}")

        # Bounded poll loop to wait for task stop with diagnostics on timeout
        try:
            max_wait_seconds = int(os.environ.get("MIGRATE_MAX_WAIT_SECONDS", "600"))
        except Exception:
            max_wait_seconds = 600
        try:
            wait_delay = int(os.environ.get("MIGRATE_WAIT_DELAY_SECONDS", "15"))
        except Exception:
            wait_delay = 15

        start_time = time.time()
        deadline = start_time + max_wait_seconds
        print(
            "Waiting up to",
            str(max_wait_seconds) + "s",
            "for task to stop (poll delay",
            str(wait_delay) + "s)",
        )

        logs = boto3.client("logs", region_name=region)

        stopped = False
        while time.time() < deadline:
            try:
                desc = ecs.describe_tasks(cluster=cluster, tasks=[task_arn])
            except Exception as e:
                print("Failed to describe task while polling:", e, file=sys.stderr)
                time.sleep(wait_delay)
                continue

            tasks_desc = desc.get("tasks", [])
            if not tasks_desc:
                print("No task description available yet; continuing to poll...")
                time.sleep(wait_delay)
                continue

            task_d = tasks_desc[0]
            last_status = task_d.get("lastStatus")
            print(
                "Task",
                task_arn,
                "lastStatus=",
                last_status,
                "desiredStatus=",
                task_d.get("desiredStatus"),
            )

            if last_status and last_status.upper() == "STOPPED":
                stopped = True
                break

            time.sleep(wait_delay)

        if not stopped:
            # Timed out waiting for task to stop; collect diagnostics
            print(
                f"Timed out waiting for task to stop after {max_wait_seconds}s",
                file=sys.stderr,
            )
            try:
                desc = ecs.describe_tasks(cluster=cluster, tasks=[task_arn])
                print("Task description at timeout:", file=sys.stderr)
                print(json.dumps(desc, default=str), file=sys.stderr)
            except Exception as ex:
                print(f"Failed to describe task at timeout: {ex}", file=sys.stderr)

            # Attempt to fetch recent CloudWatch logs for the migration
            # container if available
            try:
                # Try to infer log group/stream prefix from the
                # migrate_container log config
                log_cfg = migrate_container.get("logConfiguration", {})
                if log_cfg.get("logDriver") == "awslogs":
                    options = log_cfg.get("options", {})
                    log_group = options.get("awslogs-group")
                    if log_group:
                        now_ms = int(time.time() * 1000)
                        start_ms = int(start_time * 1000) - 60_000
                        print(
                            "Fetching CloudWatch logs from",
                            log_group,
                            "since",
                            start_ms,
                            file=sys.stderr,
                        )
                        events_resp = logs.filter_log_events(
                            logGroupName=log_group,
                            startTime=start_ms,
                            endTime=now_ms,
                            limit=200,
                        )
                        events = events_resp.get("events", [])
                        if not events:
                            print(
                                "No CloudWatch log events found for migration task",
                                file=sys.stderr,
                            )
                        else:
                            print("Recent CloudWatch log events:", file=sys.stderr)
                            for ev in events:
                                ts = ev.get("timestamp")
                                msg = ev.get("message")
                                print(f"{ts}: {msg}", file=sys.stderr)
                else:
                    print(
                        "No awslogs configuration found for migration container;",
                        "skipping CloudWatch logs fetch",
                        file=sys.stderr,
                    )
            except Exception as ex:
                print(f"Error while fetching CloudWatch logs: {ex}", file=sys.stderr)

            sys.exit(2)

        desc = ecs.describe_tasks(cluster=cluster, tasks=[task_arn])
        if not desc.get("tasks"):
            print("No task description returned after completion", file=sys.stderr)
            sys.exit(3)

        task_desc = desc["tasks"][0]
        containers = task_desc.get("containers", [])
        if not containers:
            print("No containers present in task description", file=sys.stderr)
            print(json.dumps(task_desc, default=str), file=sys.stderr)
            sys.exit(4)

        container_desc = containers[0]
        exit_code = container_desc.get("exitCode")
        reason = container_desc.get("reason", "")
        stop_reason = task_desc.get("stopReason", "")

        # If exit_code is None, the task may have been stopped
        # without container exit information
        if exit_code is None:
            print(
                "Container exit code not available. Task details:",
                json.dumps(task_desc, default=str),
                file=sys.stderr,
            )
            # Treat as failure
            sys.exit(5)

        if exit_code != 0:
            msg = (
                "Migrations failed (exit="
                + str(exit_code)
                + ", container_reason="
                + str(reason)
                + ", task_reason="
                + str(stop_reason)
                + ")"
            )
            print(msg, file=sys.stderr)
            sys.exit(exit_code)
        print("Migrations completed successfully.")
    finally:
        # No registration performed, nothing to deregister. If we had registered
        # a task definition earlier, we would deregister it here.
        pass


if __name__ == "__main__":
    main()
