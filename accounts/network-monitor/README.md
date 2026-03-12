# Network Monitor Account

This directory contains the Terraform configuration for the network-monitor AWS account.

## Resources Managed

- GitHub OIDC provider for GitHub Actions authentication
- tf-github IAM role for managing GitHub resources
- AdminRole for cross-account access from management account

## Usage

The Makefile automatically adapts to your current AWS credentials:

```bash
# From repository root
make account-network-monitor plan
make account-network-monitor apply

# Or from this directory
make plan
make apply
```

**How it works:**
- Detects if you're already in account 844347863910
- If yes: temporarily disables assume_role (uses your current credentials)
- If no: uses assume_role as configured in providers.tf
- Automatically restores providers.tf after operations

**Manual Terraform:**
```bash
terraform init
terraform plan
terraform apply
```

**Restore original providers.tf:**
```bash
make restore
```

## Prerequisites

- Access to assume `arn:aws:iam::844347863910:role/AdminRole` from the management account
- Organization ID configured in `terraform.tfvars`

**Note:** On first bootstrap, you may need to use `OrganizationAccountAccessRole` instead of `AdminRole` in `providers.tf` until the AdminRole is created. After the first apply, switch back to AdminRole.

## State File

State is stored in S3: `s3://mdekort.tfstate/network-monitor.tfstate`
