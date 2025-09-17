output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "eice_security_group_id" {
  value = aws_security_group.eice.id
}

output "melvyn_password" {
  value = aws_iam_user_login_profile.melvyn.encrypted_password
}

output "melvyn_access_key_id" {
  value = aws_iam_access_key.melvyn.id
}

output "melvyn_secret_access_key" {
  value     = aws_iam_access_key.melvyn.secret
  sensitive = true
}

output "lmbackup_name" {
  value = aws_iam_user.lmbackup.name
}

output "lmbackup_access_key_id" {
  value = aws_iam_access_key.lmbackup.id
}

output "lmbackup_secret_access_key" {
  value     = aws_iam_access_key.lmbackup.secret
  sensitive = true
}

output "homeassistant_arn" {
  value = aws_iam_user.homeassistant.arn
}

output "homeassistant_access_key_id" {
  value = aws_iam_access_key.homeassistant.id
}

output "homeassistant_secret_access_key" {
  value     = aws_iam_access_key.homeassistant.secret
  sensitive = true
}

output "generic_kms_key_arn" {
  value = aws_kms_key.generic.arn
}

output "generic_kms_key_id" {
  value = aws_kms_key.generic.key_id
}

output "generic_kms_alias_arn" {
  value = aws_kms_alias.generic.arn
}

output "admin_role_name" {
  value = aws_iam_role.admin.name
}

output "s3_lambda" {
  value = aws_s3_bucket.lambda.id
}

output "access_logs_bucket" {
  value = aws_s3_bucket.access_logs.id
}

output "cloudfront_function_no_index_arn" {
  value = aws_cloudfront_function.no_index.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_tf_aws.arn
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.default.arn
}

output "ecs_loggroup_arn" {
  value = aws_cloudwatch_log_group.ecs_default.arn
}

output "api_mdekort_domain_name" {
  value = aws_api_gateway_domain_name.api.domain_name
}
