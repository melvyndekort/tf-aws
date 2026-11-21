# Dedicated permission set for aws-idc-pim's JIT elevation bot -- never
# has a standing assignment, unlike AdministratorAccess.
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
