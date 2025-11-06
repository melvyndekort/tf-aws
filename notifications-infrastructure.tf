# EC2 Instance State Changes
resource "aws_cloudwatch_event_rule" "ec2_state_changes" {
  name        = "ec2-state-changes-notifications"
  description = "Forward EC2 instance state changes to notifications"

  event_pattern = jsonencode({
    "source" : ["aws.ec2"],
    "detail-type" : ["EC2 Instance State-change Notification"],
    "detail" : {
      "state" : ["stopped", "terminated", "stopping", "terminating"]
    }
  })
}

resource "aws_cloudwatch_event_target" "ec2_state_changes" {
  rule      = aws_cloudwatch_event_rule.ec2_state_changes.name
  target_id = "NotificationsEC2Target"
  arn       = aws_sns_topic.notifications.arn
  role_arn  = aws_iam_role.eventbridge_notifications.arn
}

# ECS Task State Change events
resource "aws_cloudwatch_event_rule" "ecs_task_state" {
  name        = "ecs-task-state-notifications"
  description = "Forward ECS task state changes to notifications"

  event_pattern = jsonencode({
    "source" : ["aws.ecs"],
    "detail-type" : ["ECS Task State Change"]
  })
}

resource "aws_cloudwatch_event_target" "ecs_task_state" {
  rule      = aws_cloudwatch_event_rule.ecs_task_state.name
  target_id = "NotificationsEcsTarget"
  arn       = aws_sns_topic.notifications.arn
  role_arn  = aws_iam_role.eventbridge_notifications.arn
}

# Auto Scaling events
resource "aws_cloudwatch_event_rule" "autoscaling_events" {
  name        = "autoscaling-events-notifications"
  description = "Alert on Auto Scaling group events"

  event_pattern = jsonencode({
    "source" : ["aws.autoscaling"],
    "detail-type" : ["EC2 Instance Launch Unsuccessful", "EC2 Instance Terminate Unsuccessful"]
  })
}

resource "aws_cloudwatch_event_target" "autoscaling_events" {
  rule      = aws_cloudwatch_event_rule.autoscaling_events.name
  target_id = "NotificationsAutoScalingTarget"
  arn       = aws_sns_topic.notifications.arn
  role_arn  = aws_iam_role.eventbridge_notifications.arn
}

# EBS volume events
resource "aws_cloudwatch_event_rule" "ebs_events" {
  name        = "ebs-events-notifications"
  description = "Alert on EBS volume attachment failures"

  event_pattern = jsonencode({
    "source" : ["aws.ec2"],
    "detail-type" : ["EBS Volume Notification"],
    "detail" : {
      "event" : ["attachVolume", "detachVolume"]
    }
  })
}

resource "aws_cloudwatch_event_target" "ebs_events" {
  rule      = aws_cloudwatch_event_rule.ebs_events.name
  target_id = "NotificationsEBSTarget"
  arn       = aws_sns_topic.notifications.arn
  role_arn  = aws_iam_role.eventbridge_notifications.arn
}
