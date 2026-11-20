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

# Allows every subaccount's own eventbridge-oidc-notifications-role (created
# by the account-bootstrap module, tf-github improvement plan Phase 2 item 2)
# to publish cross-account to this one shared topic, instead of giving every
# subaccount its own SNS topic. Same org-wide-trust shape already used for
# the state bucket's read policy (aws:PrincipalOrgID, no narrower principal
# list to maintain per-account).
resource "aws_sns_topic_policy" "notifications_org_publish" {
  arn = aws_sns_topic.notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowOrgPublish"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.notifications.arn
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = aws_organizations_organization.organization.id
          }
        }
      }
    ]
  })
}
