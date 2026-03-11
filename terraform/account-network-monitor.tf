# Network Monitor AWS Account
data "aws_caller_identity" "current" {}

module "network_monitor" {
  source = "./modules/subaccount"

  account_name           = "network-monitor"
  email                  = "aws+network-monitor@mdekort.nl"
  management_account_id  = data.aws_caller_identity.current.account_id
  organization_id        = aws_organizations_organization.organization.id

  tags = {
    Purpose     = "Network Monitoring"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

output "network_monitor_account_id" {
  value = module.network_monitor.account_id
}

