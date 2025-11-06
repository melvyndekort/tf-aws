# SNS topic for notifications
resource "aws_sns_topic" "notifications" {
  name = "aws-notifications"
}

# IAM role for EventBridge to publish to SNS
resource "aws_iam_role" "eventbridge_notifications" {
  name = "eventbridge-notifications-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_notifications" {
  name = "eventbridge-notifications-policy"
  role = aws_iam_role.eventbridge_notifications.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.notifications.arn
      }
    ]
  })
}

# AWS Health events
resource "aws_cloudwatch_event_rule" "aws_health" {
  name        = "aws-health-notifications"
  description = "Forward AWS Health events to notifications"

  event_pattern = jsonencode({
    "source": ["aws.health"],
    "detail-type": ["AWS Health Event"]
  })
}

resource "aws_cloudwatch_event_target" "aws_health" {
  rule      = aws_cloudwatch_event_rule.aws_health.name
  target_id = "NotificationsHealthTarget"
  arn       = aws_sns_topic.notifications.arn
  role_arn  = aws_iam_role.eventbridge_notifications.arn
}

# ECS Task State Change events
resource "aws_cloudwatch_event_rule" "ecs_task_state" {
  name        = "ecs-task-state-notifications"
  description = "Forward ECS task state changes to notifications"

  event_pattern = jsonencode({
    "source": ["aws.ecs"],
    "detail-type": ["ECS Task State Change"]
  })
}

resource "aws_cloudwatch_event_target" "ecs_task_state" {
  rule      = aws_cloudwatch_event_rule.ecs_task_state.name
  target_id = "NotificationsEcsTarget"
  arn       = aws_sns_topic.notifications.arn
  role_arn  = aws_iam_role.eventbridge_notifications.arn
}

# Budget alerts
resource "aws_cloudwatch_event_rule" "budget_alerts" {
  name        = "budget-alerts-notifications"
  description = "Forward AWS Budget alerts to notifications"

  event_pattern = jsonencode({
    "source": ["aws.budgets"],
    "detail-type": ["Budget Alert"]
  })
}

resource "aws_cloudwatch_event_target" "budget_alerts" {
  rule      = aws_cloudwatch_event_rule.budget_alerts.name
  target_id = "NotificationsBudgetTarget"
  arn       = aws_sns_topic.notifications.arn
  role_arn  = aws_iam_role.eventbridge_notifications.arn
}

# CloudWatch Alarms
resource "aws_cloudwatch_event_rule" "cloudwatch_alarms" {
  name        = "cloudwatch-alarms-notifications"
  description = "Forward CloudWatch alarms to notifications"

  event_pattern = jsonencode({
    "source": ["aws.cloudwatch"],
    "detail-type": ["CloudWatch Alarm State Change"],
    "detail": {
      "state": {
        "value": ["ALARM"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "cloudwatch_alarms" {
  rule      = aws_cloudwatch_event_rule.cloudwatch_alarms.name
  target_id = "NotificationsCloudWatchTarget"
  arn       = aws_sns_topic.notifications.arn
  role_arn  = aws_iam_role.eventbridge_notifications.arn
}

# EC2 Instance State Changes
resource "aws_cloudwatch_event_rule" "ec2_state_changes" {
  name        = "ec2-state-changes-notifications"
  description = "Forward EC2 instance state changes to notifications"

  event_pattern = jsonencode({
    "source": ["aws.ec2"],
    "detail-type": ["EC2 Instance State-change Notification"],
    "detail": {
      "state": ["stopped", "terminated", "stopping", "terminating"]
    }
  })
}

resource "aws_cloudwatch_event_target" "ec2_state_changes" {
  rule      = aws_cloudwatch_event_rule.ec2_state_changes.name
  target_id = "NotificationsEC2Target"
  arn       = aws_sns_topic.notifications.arn
  role_arn  = aws_iam_role.eventbridge_notifications.arn
}
