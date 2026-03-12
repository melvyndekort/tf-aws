# Network Monitor Account

This directory contains the Terraform configuration for the network-monitor AWS account.

## Resources Managed

- GitHub OIDC provider for GitHub Actions authentication
- tf-github IAM role for managing GitHub resources
- AdminRole for cross-account access from management account

## First Time Bootstrap

The subaccount needs to be bootstrapped once to create the AdminRole:

```bash
cd accounts/network-monitor
./bootstrap.sh
# In the new shell with temporary credentials:
terraform init
terraform apply
exit
```

After the first apply, switch back to AdminRole in `providers.tf`:
```hcl
assume_role {
  role_arn = "arn:aws:iam::844347863910:role/AdminRole"
}
```

## Normal Usage

```bash
cd accounts/network-monitor
terraform init
terraform plan
terraform apply
```

## Prerequisites

- Access to assume `arn:aws:iam::844347863910:role/AdminRole` from the management account
- Organization ID configured in `terraform.tfvars`

**Note:** On first bootstrap, you may need to use `OrganizationAccountAccessRole` instead of `AdminRole` in `providers.tf` until the AdminRole is created. After the first apply, switch back to AdminRole.

## State File

State is stored in S3: `s3://mdekort.tfstate/network-monitor.tfstate`
