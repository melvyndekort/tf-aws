# AWS IDC PIM Account

This directory contains the Terraform configuration for the aws-idc-pim AWS account.

## Purpose

- Registered as the IAM Identity Center **delegated administrator** (see
  `management/identity_center.tf`) — most Identity Center admin work, including
  the account assignments the planned JIT-elevation Discord bot performs for
  workload accounts, runs from here instead of the management account.
- Will also host the `aws-idc-pim` workload itself (Discord bot, API Gateway,
  Lambda, EventBridge Scheduler) once that repo is built. See
  `Tech/Homelab/planning/aws-idc-pim-2026-11-20.md` in the Obsidian vault for
  the full design.

## Resources Managed

- GitHub OIDC provider for GitHub Actions authentication
- tf-github IAM role for managing GitHub resources
- AdminRole for cross-account access from management account
- Terraform state S3 bucket

## Usage

```bash
# From repository root
make account-aws-idc-pim plan
make account-aws-idc-pim apply

# Or from this directory
make plan
make apply
```

**Local usage**: `providers.tf` assumes `OrganizationAccountAccessRole` (or `TerraformPlanRole`, via `TF_VAR_subaccount_role_name`) in account 397379012163 from whatever credentials you run Terraform with — your own session needs permission to assume one of those roles.

**CI** authenticates via OIDC and assumes `OrganizationAccountAccessRole` (apply) or `TerraformPlanRole` (PR plan). See `.github/workflows/terraform.yml`.

## State File

State is stored in S3: `s3://mdekort-tfstate-075673041815/tf-aws-aws-idc-pim.tfstate`
