# Pulsar Platform — Terraform

This is the base Terraform configuration for the Pulsar platform in AWS account
`463737305712` (us-east-1). It establishes the foundational infrastructure-as-code
structure and conventions that all downstream Pulsar infrastructure will follow.

## Prerequisites

- Terraform `>= 1.0`
- AWS credentials configured for account `463737305712` (e.g., via environment
  variables, `~/.aws/credentials`, or an AWS profile)

## Usage

Initialize the working directory to download the required providers:

```bash
terraform init
```

Review the changes Terraform will make:

```bash
terraform plan
```

Apply the configuration:

```bash
terraform apply
```

## Notes

- This is the base configuration for the Pulsar platform. No AWS resources are
  created yet — it is a foundation for future cost-aware, reproducible
  infrastructure management.
- Default tags are placeholders; adjust them to match your organization's
  tagging strategy before applying to real resources.
- Before managing real infrastructure, plan to configure a remote backend
  (e.g., S3 + DynamoDB) to avoid state loss or conflicts.
