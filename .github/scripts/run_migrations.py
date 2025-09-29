#!/usr/bin/env python3
import copy
import json
import os
import sys

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

    migrate_td_def = {
        "family": f"{family}-migrate",
        "taskRoleArn": base_td.get("taskRoleArn"),
        "executionRoleArn": base_td.get("executionRoleArn"),
        "networkMode": base_td["networkMode"],
        "containerDefinitions": [migrate_container],
        "requiresCompatibilities": base_td.get("requiresCompatibilities", []),
        "cpu": base_td.get("cpu"),
        "memory": base_td.get("memory"),
        "runtimePlatform": base_td.get("runtimePlatform"),
        "volumes": base_td.get("volumes", []),
    }

    register_resp = ecs.register_task_definition(**migrate_td_def)
    migrate_td_arn = register_resp["taskDefinition"]["taskDefinitionArn"]

    try:
        run_resp = ecs.run_task(
            cluster=cluster,
            launchType="FARGATE",
            taskDefinition=migrate_td_arn,
            count=1,
            networkConfiguration={
                "awsvpcConfiguration": {
                    "subnets": subnets,
                    "securityGroups": [service_sg],
                    "assignPublicIp": "DISABLED",
                }
            },
        )

        tasks = run_resp.get("tasks", [])
        if not tasks:
            print("Failed to start migration task", file=sys.stderr)
            sys.exit(1)

        task_arn = tasks[0]["taskArn"]
        print(f"Started migration task: {task_arn}")

        waiter = ecs.get_waiter("tasks_stopped")
        waiter.wait(cluster=cluster, tasks=[task_arn])

        desc = ecs.describe_tasks(cluster=cluster, tasks=[task_arn])
        task_desc = desc["tasks"][0]
        container_desc = task_desc["containers"][0]
        exit_code = container_desc.get("exitCode", 1)
        reason = container_desc.get("reason", "")
        stop_reason = task_desc.get("stopReason", "")

        if exit_code != 0:
            print(
                (
                    "Migrations failed (exit="
                    + f"{exit_code}, container_reason={reason},"
                    + f" task_reason={stop_reason})"
                ),
                file=sys.stderr,
            )
            sys.exit(exit_code)
        print("Migrations completed successfully.")
    finally:
        ecs.deregister_task_definition(taskDefinition=migrate_td_arn)


if __name__ == "__main__":
    main()
