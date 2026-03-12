# Network Monitor AWS Account
module "network_monitor" {
  source = "../modules/subaccount"

  account_name = "network-monitor"
  email        = "aws+network-monitor@mdekort.nl"

  tags = {
    Purpose     = "Network Monitoring"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

output "network_monitor_account_id" {
  description = "Network Monitor AWS account ID"
  value       = module.network_monitor.account_id
}

