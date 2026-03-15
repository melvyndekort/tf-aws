# Account Bootstrap & Authentication Architecture

This document describes how new AWS subaccounts are created, bootstrapped, and integrated with GitHub Actions for automated deployments.

## Overview

The infrastructure uses a three-repository chain to go from an empty AWS account to a fully operational workload with CI/CD:

```
tf-aws                    tf-github                 workload repos
──────                    ─────────                 ──────────────
Creates AWS account       Creates per-repo          Use OIDC to
Bootstraps OIDC +         IAM roles in the          authenticate
IAM roles for             correct account           directly into
tf-github access          Sets AWS_ROLE_ARN         their target
                          secret on each repo       account
```

Each repository has a distinct responsibility and runs in a specific security context. The separation ensures least-privilege access and clear ownership boundaries.

## The Dependency Chain

### Phase 1: Account Creation (tf-aws, management context)

The management account configuration creates the subaccount via AWS Organizations and provisions a Terraform state bucket in the management account for the bootstrap state.

Resources created:
- `aws_organizations_account` — the new AWS account
- `aws_s3_bucket` — state bucket for the bootstrap configuration (in management account)

At this point, the only role that exists in the new account is `OrganizationAccountAccessRole`, which AWS creates automatically. This role trusts the management account root and has `AdministratorAccess`.

### Phase 2: Account Bootstrap (tf-aws, subaccount context)

A separate Terraform root under `accounts/<name>/` runs against the new subaccount. It uses the `account-bootstrap` module to create the foundational IAM infrastructure.

This phase **must** use `OrganizationAccountAccessRole` via `assume_role` in the provider configuration. There is no alternative — no other roles or OIDC providers exist yet. This is the unavoidable chicken-and-egg constraint.

Resources created by the `account-bootstrap` module:
- **GitHub OIDC provider** — registers `token.actions.githubusercontent.com` as an identity provider in the subaccount
- **`github-actions-tf-github` role** — allows the tf-github repository to authenticate via OIDC and manage IAM roles in this account. Trusts both direct OIDC from tf-github and cross-account assumption from the management account's tf-github role
- **`AdminRole`** — the primary administrative role, with a trust policy allowing:
  - The `melvyn` IAM user (with MFA)
  - The `YubikeyRole` from the management account (with org ID verification)
  - GitHub Actions roles from the management account (with principal ARN pattern matching)
- **Terraform state bucket** — `mdekort-tfstate-<account-id>` in the subaccount, used by workload repos

After this phase, the subaccount has everything needed for tf-github to operate.

### Phase 3: Role Provisioning (tf-github)

The tf-github repository is the central role broker. It manages all GitHub repositories and their AWS access.

Repository definitions in `repositories.yaml` include an optional `aws_account` field. When present, tf-github:

1. Groups repositories by target account
2. Uses a per-account AWS provider (assuming into `github-actions-tf-github` in each subaccount)
3. Creates a dedicated OIDC role per repository in the correct account (e.g., `github-actions-<repo-name>`)
4. Sets the `AWS_ROLE_ARN` GitHub Actions secret on each repository to the corresponding role ARN

The OIDC trust policy on each role restricts access to `ref:refs/heads/main` of the specific repository.

### Phase 4: Workload Deployment (workload repos)

Workload repositories authenticate directly into their target account via OIDC using the role created by tf-github. No role chaining or cross-account assumption is needed.

- The provider configuration has no `assume_role` block
- State is stored in the subaccount's own bucket (`mdekort-tfstate-<account-id>`)
- The `AWS_ROLE_ARN` secret is managed by tf-github — workload repos never configure it manually

## Authentication Methods

### GitHub Actions (CI/CD)

All CI/CD authentication uses OIDC — no long-lived credentials are stored anywhere.

- **tf-aws**: OIDC into management account, then `assume_role` into subaccounts via `OrganizationAccountAccessRole` (bootstrap only)
- **tf-github**: OIDC into management account (where it runs), then `assume_role` into subaccounts via `github-actions-tf-github` to create per-repo roles
- **Workload repos**: Direct OIDC into target account via their dedicated `github-actions-<repo-name>` role

### Human Access (CLI/Console)

Two paths exist for human access to any account in the organization:

- **YubiKey (Roles Anywhere)**: Authenticate via PIV certificate → assume `YubikeyRole` in management account → assume `AdminRole` in any subaccount. The trust policy verifies the organization ID.
- **IAM User with MFA**: Authenticate as `melvyn` user → assume `AdminRole` directly (MFA required).

Both paths lead to `AdminRole`, which exists in every account via the `account-bootstrap` module.

## State Management Strategy

Two state storage patterns are used, each for a specific reason:

| Context | State Location | Reason |
|---------|---------------|--------|
| Bootstrap (`tf-aws/accounts/*`) | Management account bucket | The subaccount's state bucket doesn't exist yet when bootstrap first runs. The CI role (`OrganizationAccountAccessRole`) has access to the management bucket. |
| Workload repos | Subaccount bucket (`mdekort-tfstate-<account-id>`) | The workload's OIDC role lives in the subaccount and has direct access. No cross-account access needed. |

## CI/CD Pipeline Ordering

The GitHub Actions workflow in tf-aws enforces correct ordering:

1. The `management` job runs first — creates accounts and state buckets
2. The `subaccounts` job runs after `management` — bootstraps OIDC and IAM roles

After tf-aws completes, tf-github must run to create per-repo roles and set secrets. This is a manual dependency — there is no cross-repo workflow trigger.

### Deployment sequence for a new subaccount

1. **tf-aws**: Add account to `management/` and bootstrap config to `accounts/<name>/`. Merge to main. CI creates the account and bootstraps it.
2. **tf-github**: Add the subaccount provider and module instance to `github-oidc-roles.tf`. Add workload repos with `aws_account` in `repositories.yaml`. Merge to main. CI creates OIDC roles and sets secrets.
3. **Workload repo**: Configure `providers.tf` with the subaccount's state bucket and region. Push to main. CI authenticates via OIDC and deploys.

## Why OrganizationAccountAccessRole Cannot Be Avoided

The bootstrap phase (tf-aws subaccount context) uses `OrganizationAccountAccessRole` because:

- The OIDC provider doesn't exist yet → no OIDC authentication possible
- `AdminRole` doesn't exist yet → no cross-account role assumption possible
- `github-actions-tf-github` doesn't exist yet → tf-github can't operate
- The subaccount state bucket doesn't exist yet → state must live in management account

This role is only used by tf-aws during bootstrap. Once the account is set up, no other repository or workflow ever uses it. The `account-bootstrap` module creates all the roles needed for subsequent access.

## Adding a New Subaccount

### In tf-aws

1. Add the account resource using the `subaccount` module in `management/`:

```hcl
module "<name>" {
  source       = "../modules/subaccount"
  account_name = "<name>"
  email        = "aws+<name>@<domain>"
  tags         = { Purpose = "...", Environment = "...", ManagedBy = "Terraform" }
}

output "<name>_account_id" {
  value = module.<name>.account_id
}
```

2. Create `accounts/<name>/` with:
   - `providers.tf` — backend in management bucket, `assume_role` into `OrganizationAccountAccessRole`
   - `main.tf` — invokes `account-bootstrap` module
   - `variables.tf` and `terraform.tfvars` — organization ID and management account ID
   - `Makefile` — local development convenience

3. Add the account to the CI workflow matrix in `.github/workflows/terraform.yml`.

### In tf-github

1. Add a provider block for the new account in `github-oidc-roles.tf`:

```hcl
provider "aws" {
  alias  = "account_<id>"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::<id>:role/external/github-actions-tf-github"
  }
}
```

2. Add a module instance:

```hcl
module "oidc_roles_<id>" {
  source     = "./oidc_role"
  github_org = local.github_org
  repos      = local.oidc_repos_by_account["<id>"]
  providers  = { aws = aws.account_<id> }
}
```

3. Merge `all_role_arns` to include the new module's output.

4. Add workload repositories to `repositories.yaml` with `aws_account: "<id>"`.

### In the workload repo

Configure `providers.tf` to use the subaccount's state bucket and no `assume_role`. The `AWS_ROLE_ARN` secret is set automatically by tf-github.

## Security Properties

- **No long-lived credentials** — all CI/CD uses OIDC with short-lived tokens
- **Least privilege role chaining** — each repo gets its own IAM role, scoped to a single account
- **Organization boundary enforcement** — cross-account trust policies verify `aws:PrincipalOrgID`
- **Branch restriction** — OIDC subject claims are locked to `refs/heads/main`
- **MFA enforcement** — all human access requires MFA or hardware key authentication
- **Bootstrap isolation** — `OrganizationAccountAccessRole` is only used during initial account setup, never by workload repos
