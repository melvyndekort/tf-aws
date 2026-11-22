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
