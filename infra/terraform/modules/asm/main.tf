resource "aws_secretsmanager_secret" "db" {
  name        = var.secret_name
  description = "Database credentials for vox-api"
  tags = merge(var.tags, {
    Name = var.secret_name
  })
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = var.secret_string
}

resource "aws_secretsmanager_secret_policy" "db_policy" {
  count      = length(trimspace(var.secret_access_policy_json)) > 0 ? 1 : 0
  secret_arn = aws_secretsmanager_secret.db.arn
  policy     = var.secret_access_policy_json
}
