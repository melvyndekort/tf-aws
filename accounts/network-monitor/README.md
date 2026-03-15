# Network Monitor Account

This directory contains the Terraform configuration for the network-monitor AWS account.

## Resources Managed

- GitHub OIDC provider for GitHub Actions authentication
- tf-github IAM role for managing GitHub resources
- AdminRole for cross-account access from management account
- Terraform state S3 bucket

## Usage

```bash
# From repository root
make account-network-monitor plan
make account-network-monitor apply

# Or from this directory
make plan
make apply
```

**Local usage** requires credentials in the target account (844347863910). The `providers.tf` has no `assume_role` — it uses your current credentials directly.

**CI** creates a `providers_override.tf` at runtime to add `assume_role` into `OrganizationAccountAccessRole`. See `.github/workflows/terraform.yml`.

## State File

State is stored in S3: `s3://mdekort-tfstate-075673041815/tf-aws-network-monitor.tfstate`
