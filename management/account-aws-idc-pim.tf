# AWS IDC PIM Account
#
# Dedicated subaccount serving as the IAM Identity Center delegated
# administrator. Registering it here means most Identity Center admin work
# (critically, the planned JIT-elevation Discord bot's account assignments
# for workload accounts) never has to touch the management account
# directly. The one exception AWS enforces regardless of delegation --
# assignments targeting the management account itself -- stays handled from
# here via a narrowly-scoped cross-account role, not by widening this
# account's own reach.
#
# This account will also host the aws-idc-pim workload itself (the Discord
# bot + API Gateway + Lambda + EventBridge Scheduler) once that repo is
# built. See Tech/Homelab/planning/aws-idc-pim-2026-11-20.md for the full
# design and open items.
module "aws_idc_pim" {
  source = "../modules/subaccount"

  account_name = "aws-idc-pim"
  email        = "aws+aws-idc-pim@mdekort.nl"

  tags = {
    Purpose     = "IAM Identity Center delegated admin + JIT elevation bot"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

output "aws_idc_pim_account_id" {
  description = "AWS IDC PIM AWS account ID"
  value       = module.aws_idc_pim.account_id
}
