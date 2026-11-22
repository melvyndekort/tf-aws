# Minecraft Server Account
#
# Dedicated subaccount for the minecraft-server repo's AWS footprint: the
# ECS Fargate Minecraft server + EFS world storage, and its Discord bot
# (being redesigned as a Lambda + HTTP-Interactions bot in the same repo,
# replacing the current always-on container + static IAM user key). This is
# priority #1 on the subaccount-migration backlog in the melvyn-aws-terraform
# skill's references/subaccount-migration.md -- isolating it bounds (and,
# with the bot redesign, eliminates) what a leaked standing credential could
# reach. See Tech/Homelab/planning/minecraft-subaccount-and-lambda-bot-migration.md
# for the full plan. Named to match the repo, same as network-monitor's
# subaccount sharing its repo's name.
module "minecraft_server" {
  source = "../modules/subaccount"

  account_name = "minecraft-server"
  email        = "aws+minecraft-server@mdekort.nl"

  tags = {
    Purpose     = "Minecraft server (ECS) + Discord control bot (Lambda)"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

output "minecraft_server_account_id" {
  description = "Minecraft Server AWS account ID"
  value       = module.minecraft_server.account_id
}
