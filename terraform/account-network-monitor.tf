# Network Monitor AWS Account
# Dedicated account for network monitoring infrastructure

resource "aws_organizations_account" "network_monitor" {
  name      = "network-monitor"
  email     = "aws+network-monitor@mdekort.nl"
  role_name = "OrganizationAccountAccessRole"

  tags = {
    Purpose     = "Network Monitoring"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

output "network_monitor_account_id" {
  description = "AWS Account ID for network-monitor"
  value       = aws_organizations_account.network_monitor.id
}

output "network_monitor_account_arn" {
  description = "AWS Account ARN for network-monitor"
  value       = aws_organizations_account.network_monitor.arn
}
