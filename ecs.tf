resource "aws_cloudwatch_log_group" "ecs_default" {
  name              = "ecs-default"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "default" {
  name = "default"

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.generic.key_id
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_default.name
      }
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "default" {
  cluster_name = aws_ecs_cluster.default.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}
