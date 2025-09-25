# Security Policy

## Reporting Security Vulnerabilities

If you discover a security vulnerability in this Terraform configuration, please report it responsibly:

### How to Report

- **Email**: [security@mdekort.nl](mailto:security@mdekort.nl)
- **Subject**: `[SECURITY] tf-aws vulnerability report`

### What to Include

Please provide the following information:
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Suggested remediation (if known)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial assessment**: Within 1 week
- **Resolution**: Depends on severity and complexity

## Security Considerations

### ⚠️ Important Disclaimers

This repository contains infrastructure-as-code for personal use. Users should be aware:

- **No warranty**: Code provided "as is" without security guarantees
- **Review required**: Always review configurations before deployment
- **Environment-specific**: Adapt security settings for your use case
- **Credentials**: Never commit secrets or credentials to version control

### 🔒 Built-in Security Features

This configuration implements several security best practices:

- **Encryption**: KMS encryption for all sensitive data
- **Access control**: IAM roles with least privilege principles
- **MFA enforcement**: Multi-factor authentication required
- **Network security**: VPC with proper subnet segmentation
- **Regional restrictions**: Resources limited to EU-West-1
- **Audit logging**: CloudWatch integration for monitoring

### 🛡️ Security Recommendations

When using this configuration:

1. **Review all settings** before applying to your environment
2. **Update credentials** and replace example values
3. **Enable additional monitoring** as needed for your use case
4. **Regular updates**: Keep Terraform and providers updated
5. **State file security**: Ensure Terraform state is properly secured
6. **Access reviews**: Regularly audit IAM permissions

## Supported Versions

Security updates are provided for:

| Version | Supported |
|---------|-----------|
| Latest  | ✅        |
| Previous| ❌        |

Only the latest version receives security updates. Please ensure you're using the most recent configuration.

## Security Resources

- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [Terraform Security Guide](https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables)
- [OWASP Infrastructure as Code Security](https://owasp.org/www-project-devsecops-guideline/)