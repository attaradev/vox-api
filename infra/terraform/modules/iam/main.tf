resource "aws_iam_role" "ecs_task_execution" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json

  tags = {
    Name        = var.role_name
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy" "ecs_task_custom_policy" {
  name   = "ecs-task-custom-policy"
  role   = aws_iam_role.ecs_task_execution.id
  policy = var.inline_policy_json
}

data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
