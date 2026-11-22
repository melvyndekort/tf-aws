# Minecraft Server Account

This directory contains the Terraform configuration for the minecraft-server AWS account.

## Resources Managed

- GitHub OIDC provider for GitHub Actions authentication
- tf-github IAM role for managing GitHub resources
- AdminRole for cross-account access from management account
- Terraform state S3 bucket

## Usage

```bash
# From repository root
make account-minecraft-server plan
make account-minecraft-server apply

# Or from this directory
make plan
make apply
```

**Local usage** requires credentials in the target account (805751386945). The `providers.tf` has no `assume_role` — it uses your current credentials directly.

**CI** creates a `providers_override.tf` at runtime to add `assume_role` into `OrganizationAccountAccessRole`. See `.github/workflows/terraform.yml`.

## State File

State is stored in S3: `s3://mdekort-tfstate-075673041815/tf-aws-minecraft-server.tfstate`
