# Root account usage
resource "aws_cloudwatch_event_rule" "root_usage" {
  name        = "root-usage-notifications"
  description = "Alert on root account usage"

  event_pattern = jsonencode({
    "detail-type" : ["AWS Console Sign In via CloudTrail"],
    "detail" : {
      "userIdentity" : {
        "type" : ["Root"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "root_usage" {
  rule      = aws_cloudwatch_event_rule.root_usage.name
  target_id = "NotificationsRootTarget"
  arn       = aws_sns_topic.notifications.arn
  role_arn  = aws_iam_role.eventbridge_notifications.arn
}

# IAM policy changes
resource "aws_cloudwatch_event_rule" "iam_changes" {
  name        = "iam-changes-notifications"
  description = "Alert on IAM policy and role changes"

  event_pattern = jsonencode({
    "source" : ["aws.iam"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventName" : [
        "CreateRole", "DeleteRole", "AttachRolePolicy", "DetachRolePolicy",
        "CreatePolicy", "DeletePolicy", "CreateUser", "DeleteUser"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "iam_changes" {
  rule      = aws_cloudwatch_event_rule.iam_changes.name
  target_id = "NotificationsIAMTarget"
  arn       = aws_sns_topic.notifications.arn
  role_arn  = aws_iam_role.eventbridge_notifications.arn
}

# Security group changes
resource "aws_cloudwatch_event_rule" "security_group_changes" {
  name        = "security-group-changes-notifications"
  description = "Alert on security group rule changes"

  event_pattern = jsonencode({
    "source" : ["aws.ec2"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventName" : [
        "AuthorizeSecurityGroupIngress", "RevokeSecurityGroupIngress",
        "AuthorizeSecurityGroupEgress", "RevokeSecurityGroupEgress"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "security_group_changes" {
  rule      = aws_cloudwatch_event_rule.security_group_changes.name
  target_id = "NotificationsSecurityGroupTarget"
  arn       = aws_sns_topic.notifications.arn
  role_arn  = aws_iam_role.eventbridge_notifications.arn
}

# S3 bucket policy changes
resource "aws_cloudwatch_event_rule" "s3_policy_changes" {
  name        = "s3-policy-changes-notifications"
  description = "Alert on S3 bucket policy changes"

  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventName" : [
        "PutBucketPolicy", "DeleteBucketPolicy", "PutBucketAcl"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "s3_policy_changes" {
  rule      = aws_cloudwatch_event_rule.s3_policy_changes.name
  target_id = "NotificationsS3Target"
  arn       = aws_sns_topic.notifications.arn
  role_arn  = aws_iam_role.eventbridge_notifications.arn
}
