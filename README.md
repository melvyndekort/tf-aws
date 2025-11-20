# tf-aws

A comprehensive Terraform configuration for managing centralized AWS infrastructure resources with security best practices, automated CI/CD, and multi-service integration.

## 🏗️ Architecture Overview

This repository manages a complete AWS infrastructure setup including networking, security, compute, storage, and identity management components. The infrastructure is designed with security-first principles, automated deployment, and integration with external services like Cloudflare.

## 🚀 Key Features

### 🔐 Security & Identity Management
- **Multi-Factor Authentication (MFA)** enforcement for all user access
- **YubiKey-based authentication** via AWS IAM Roles Anywhere
- **Strict password policy** (40+ characters, complexity requirements)
- **Role-based access control** with separate Admin and Finance roles
- **KMS encryption** for all sensitive data and state files
- **AWS Organizations** setup for centralized account management

### 🌐 Networking Infrastructure
- **VPC with dual-stack IPv4/IPv6** support across 3 availability zones
- **Public and private subnets** with proper CIDR allocation
- **Security groups** and network ACLs for traffic control
- **EC2 Instance Connect Endpoint** for secure SSH access
- **Regional restrictions** preventing resource creation outside EU-West-1

### ☁️ Compute & Container Services
- **ECS Fargate cluster** with spot instance support
- **CloudWatch logging** with KMS encryption
- **Execute command configuration** for secure container access
- **Capacity providers** for cost optimization

### 📦 Storage & Data Management
- **S3 buckets** for Terraform state, Lambda functions, and access logs
- **Versioning and lifecycle policies** for cost optimization
- **Server-side encryption** with customer-managed KMS keys
- **Public access blocking** for security compliance

### 🔧 API & Web Services
- **API Gateway** with custom domain and SSL certificates
- **CloudFront functions** for request processing
- **ACM certificates** with automated DNS validation
- **Cloudflare integration** for DNS management and CDN

### 🤖 Automation & CI/CD
- **GitHub Actions workflow** for automated Terraform deployment
- **OIDC authentication** for secure AWS access from GitHub
- **Automated planning and applying** on main branch pushes
- **Pull request validation** with plan output comments
- **Dependabot integration** for dependency updates

### 📊 Monitoring & Logging
- **CloudWatch log groups** with retention policies
- **VPC Flow Logs** capability (configurable)
- **Athena integration** for log analysis
- **Access logging** for S3 and other services

## 📁 Project Structure

```
tf-aws/
├── .github/workflows/     # CI/CD automation
├── terraform/             # Terraform configuration
│   ├── *.tf              # Infrastructure definitions
│   ├── terraform.tfvars  # Variable definitions
│   └── files/            # Static files (certificates, scripts)
└── README.md             # This file
```

### Core Configuration Files

| File | Purpose |
|------|---------|
| `providers.tf` | Provider configuration and backend setup |
| `vpc.tf` | Network infrastructure and VPC configuration |
| `iam.tf` | Identity and access management |
| `kms.tf` | Key management and encryption |
| `users.tf` | IAM users and access keys |
| `roles_anywhere.tf` | YubiKey-based authentication setup |
| `ecs.tf` | Container orchestration platform |
| `api_gateway.tf` | API management and custom domains |
| `lambda.tf` | Serverless function storage |
| `cloudfront.tf` | CDN and edge functions |
| `organizations.tf` | AWS Organizations configuration |
| `state-bucket.tf` | Terraform state storage |

## 🛠️ Prerequisites

- **Terraform** ~> 1.6.0
- **AWS CLI** configured with appropriate permissions
- **Cloudflare account** with API token access
- **YubiKey** with PIV certificate (for Roles Anywhere)
- **PGP key** for password encryption

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone <repository-url>
cd tf-aws
```

### 2. Configure Variables
Update `terraform/terraform.tfvars` with your specific values:
```hcl
account_id = "your-aws-account-id"
region     = "eu-west-1"
pgp_key    = "your-pgp-public-key"
```

### 3. Initialize Terraform
```bash
cd terraform
terraform init
```

### 4. Plan and Apply
```bash
terraform plan
terraform apply
```

## 🔧 Configuration Details

### Network Configuration
- **VPC CIDR**: 172.16.0.0/16
- **Private Subnets**: 172.16.101-103.0/24
- **Public Subnets**: 172.16.111-113.0/24
- **IPv6**: Enabled with automatic assignment
- **Availability Zones**: eu-west-1a, eu-west-1b, eu-west-1c

### Security Features
- **Password Policy**: 40+ character minimum, 89-day rotation
- **MFA Required**: All role assumptions require MFA
- **KMS Encryption**: All data encrypted with customer-managed keys
- **Regional Restrictions**: EC2 resources limited to EU-West-1

### User Management
- **Admin User**: `melvyn` with MFA-protected role access
- **Service Users**: `lmbackup` and `homeassistant` for automation
- **Role Hierarchy**: YubiKey → Admin/Finance roles

## 🔐 Security Best Practices

### Implemented Security Measures
- ✅ **Encryption at rest** for all storage services
- ✅ **Encryption in transit** with TLS/SSL certificates
- ✅ **Least privilege access** with granular IAM policies
- ✅ **Multi-factor authentication** enforcement
- ✅ **Hardware security keys** (YubiKey) support
- ✅ **Network segmentation** with VPC and security groups
- ✅ **Audit logging** with CloudWatch integration
- ✅ **Automated security updates** via Dependabot

### Access Control Matrix
| User/Role | Admin Access | Billing Access | Service Access |
|-----------|-------------|----------------|----------------|
| melvyn (MFA) | ✅ | ✅ | ✅ |
| YubiKey Role | ✅ | ✅ | ✅ |
| Finance Role | ❌ | ✅ | ❌ |
| Service Users | ❌ | ❌ | Limited |

## 🚀 CI/CD Pipeline

### GitHub Actions Workflow
The repository includes a comprehensive CI/CD pipeline that:

1. **Validates** Terraform configuration on every PR
2. **Plans** infrastructure changes and comments on PRs
3. **Applies** changes automatically on main branch pushes
4. **Uses OIDC** for secure AWS authentication
5. **Supports** manual workflow dispatch

### Deployment Triggers
- **Pull Requests**: Validation and planning
- **Main Branch Push**: Automatic deployment
- **Manual Trigger**: On-demand deployment
- **File Changes**: Only triggers on `.tf` and `.tfvars` changes

## 📊 Outputs and Integration

### Available Outputs
The configuration provides numerous outputs for integration with other systems:
- VPC and subnet IDs
- Security group IDs
- IAM user credentials (encrypted)
- KMS key ARNs
- ECS cluster information
- API Gateway domains
- S3 bucket names

### External Integrations
- **Cloudflare**: DNS management and CDN
- **Home Assistant**: SNS notifications via dedicated user
- **Backup Systems**: S3 access via `lmbackup` user
- **Remote State**: Cross-project state sharing

## 🔄 State Management

### Remote State Configuration
- **Backend**: S3 with DynamoDB locking
- **Encryption**: KMS-encrypted state files
- **Versioning**: Enabled with lifecycle policies
- **Access Control**: Restricted to authorized users only

### State Sharing
The configuration supports remote state sharing with other Terraform projects, particularly the `tf-cloudflare` project for DNS management.

## 🛡️ Compliance and Governance

### AWS Well-Architected Framework
This infrastructure follows AWS Well-Architected principles:
- **Security**: Encryption, IAM, and network controls
- **Reliability**: Multi-AZ deployment and backup strategies
- **Performance**: Optimized instance types and caching
- **Cost Optimization**: Lifecycle policies and spot instances
- **Operational Excellence**: Automated deployment and monitoring

### Compliance Features
- **Data residency** controls (EU-West-1 only)
- **Audit trails** via CloudWatch and CloudTrail integration
- **Access logging** for all services
- **Encryption standards** compliance

## 🤝 Contributing

### Development Workflow
1. Create feature branch from `main`
2. Make infrastructure changes
3. Test locally with `terraform plan`
4. Submit pull request
5. Review automated validation results
6. Merge after approval

### Code Standards
- Use consistent naming conventions
- Include appropriate tags on all resources
- Follow security best practices
- Document significant changes

## 📞 Support and Maintenance

### Monitoring
- **CloudWatch**: Centralized logging and metrics
- **GitHub Actions**: Deployment status and notifications
- **Dependabot**: Automated dependency updates

### Backup and Recovery
- **State Files**: Versioned and encrypted in S3
- **Configuration**: Version controlled in Git
- **Secrets**: Encrypted with PGP keys

## 📄 License

This project is licensed under the terms specified in the LICENSE file.

---

**Note**: This infrastructure is designed for personal/development use. For production environments, consider additional security measures, compliance requirements, and disaster recovery procedures.
