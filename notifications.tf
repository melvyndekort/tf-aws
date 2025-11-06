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
