# Hermes Agent AWS Account
module "hermes_agent" {
  source = "../modules/subaccount"

  account_name = "hermes-agent"
  email        = "aws+hermes-agent@mdekort.nl"

  tags = {
    Purpose     = "Hermes Agent"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

output "hermes_agent_account_id" {
  description = "Hermes Agent AWS account ID"
  value       = module.hermes_agent.account_id
}
