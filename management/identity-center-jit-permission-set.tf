# Dedicated permission set for aws-idc-pim's JIT elevation bot, separate
# from the standing aws_ssoadmin_permission_set.administrator used by the
# aws-users group's everyday admin access.
#
# Why this exists: a live /aws-elevate test against aws_ssoadmin_permission_set
# .administrator failed with AccessDeniedException on sso:CreateAccountAssignment
# from the delegated-admin account (397379012163), even with a correct,
# explicit-resource IAM policy. Root cause (confirmed via
# list-account-assignments): that permission set already has a standing
# assignment to the MANAGEMENT ACCOUNT ITSELF (the aws-users group's normal
# admin access). AWS's documented best practice/restriction: "a permission
# set used for access to the management account can only be modified by an
# IAM Identity Center administrator from the management account" -- and in
# practice this blocks the delegated administrator from managing ANY
# assignment for that permission set, in ANY account, not just the
# management account itself.
#
# Fix: this bot never touches aws_ssoadmin_permission_set.administrator.
# It uses this permission set exclusively, which never has a standing
# assignment anywhere -- so delegated administration can always manage it
# freely, in any account including the management account (via the separate
# narrow root_elevation_role for that one case).
resource "aws_ssoadmin_permission_set" "administrator_jit" {
  name             = "AdministratorAccessJIT"
  description      = "Full administrator access, JIT-only (aws-idc-pim bot) -- never has a standing assignment"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT1H"
}

resource "aws_ssoadmin_managed_policy_attachment" "administrator_jit" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.administrator_jit.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
