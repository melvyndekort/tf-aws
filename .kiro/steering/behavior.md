# tf-aws

> For global standards, way-of-workings, and pre-commit checklist, see `~/.kiro/steering/behavior.md`

## Role

Cloud Engineer specializing in AWS Organizations and Terraform.

## Critical: Read BOOTSTRAP.md First

Before making changes to account setup, IAM, OIDC, or CI/CD, read `BOOTSTRAP.md` for the full authentication and bootstrap architecture. Understand the three-phase dependency chain: tf-aws → tf-github → workload repos.

## Key Rules

- Bootstrap uses `OrganizationAccountAccessRole` because nothing else exists yet. This is intentional.
- All CI/CD uses OIDC. Never introduce static access keys for automation.
- New projects MUST use dedicated AWS subaccounts, not the management account.

## Repository Structure

- `management/` — Management account Terraform configuration
- `accounts/<name>/` — Subaccount bootstrap configurations
- `modules/account-bootstrap/` — Shared module: OIDC provider, AdminRole, tf-github role, state bucket
- `modules/subaccount/` — Shared module: AWS Organizations account creation
- `BOOTSTRAP.md` — Full bootstrap and authentication architecture documentation

## Authentication Architecture (3 phases)

1. **tf-aws management** creates AWS accounts and state buckets
2. **tf-aws subaccount bootstrap** creates OIDC providers, AdminRole, and tf-github role (via `OrganizationAccountAccessRole`)
3. **tf-github** (separate repo) creates per-repo OIDC roles and sets `AWS_ROLE_ARN` secrets

## CI/CD

- Management job runs first, subaccounts run after (matrix strategy)
- Subaccounts use a `providers_override.tf` created at runtime for role assumption
- Local development uses `providers.tf` directly (no assume_role)

## Related Repositories

- `~/src/melvyndekort/tf-github` — Central role broker: manages GitHub repos and per-repo OIDC roles
- `~/src/melvyndekort/tf-cloudflare` — Cloudflare DNS and tunnel configuration
- `~/src/melvyndekort/network-monitor` — Reference implementation of the subaccount pattern
