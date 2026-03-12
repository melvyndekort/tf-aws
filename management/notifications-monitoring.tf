# AWS Health events
resource "aws_cloudwatch_event_rule" "aws_health" {
  name        = "aws-health-notifications"
  description = "Forward AWS Health events to notifications"

  event_pattern = jsonencode({
    "source" : ["aws.health"],
    "detail-type" : ["AWS Health Event"]
  })
}

resource "aws_cloudwatch_event_target" "aws_health" {
  rule      = aws_cloudwatch_event_rule.aws_health.name
  target_id = "NotificationsHealthTarget"
  arn       = aws_sns_topic.notifications.arn
  role_arn  = aws_iam_role.eventbridge_notifications.arn
}

# Budget alerts
resource "aws_cloudwatch_event_rule" "budget_alerts" {
  name        = "budget-alerts-notifications"
  description = "Forward AWS Budget alerts to notifications"

  event_pattern = jsonencode({
    "source" : ["aws.budgets"],
    "detail-type" : ["Budget Alert"]
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
    "source" : ["aws.cloudwatch"],
    "detail-type" : ["CloudWatch Alarm State Change"],
    "detail" : {
      "state" : {
        "value" : ["ALARM"]
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

# ACM certificate expiration
resource "aws_cloudwatch_event_rule" "acm_expiration" {
  name        = "acm-expiration-notifications"
  description = "Alert on ACM certificate expiration"

  event_pattern = jsonencode({
    "source" : ["aws.acm"],
    "detail-type" : ["ACM Certificate Approaching Expiration"]
  })
}

resource "aws_cloudwatch_event_target" "acm_expiration" {
  rule      = aws_cloudwatch_event_rule.acm_expiration.name
  target_id = "NotificationsACMTarget"
  arn       = aws_sns_topic.notifications.arn
  role_arn  = aws_iam_role.eventbridge_notifications.arn
}

# Lambda function updates
resource "aws_cloudwatch_event_rule" "lambda_deployments" {
  name        = "lambda-deployment-notifications"
  description = "Forward Lambda function updates to notifications"

  event_pattern = jsonencode({
    "source" : ["aws.lambda"],
    "detail-type" : ["Lambda Function Update"]
  })
}

resource "aws_cloudwatch_event_target" "lambda_deployments" {
  rule      = aws_cloudwatch_event_rule.lambda_deployments.name
  target_id = "NotificationsLambdaTarget"
  arn       = aws_sns_topic.notifications.arn
  role_arn  = aws_iam_role.eventbridge_notifications.arn
}
