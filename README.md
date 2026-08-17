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

## Network Layer

The configuration provisions a foundational VPC network layer via the
`modules/network` module. This is a prerequisite for all downstream compute and
database workloads.

### Resources Created

- **VPC** (`Pulsar VPC`) with CIDR `10.0.0.0/16`, DNS resolution and DNS hostnames
  enabled.
- **Internet Gateway** attached to the VPC to provide public internet access.
- **Public subnets** across three availability zones:
  - `us-east-1a` → `10.0.1.0/24`
  - `us-east-1b` → `10.0.2.0/24`
  - `us-east-1c` → `10.0.3.0/24`
  - Tagged `Tier=public` and `map_public_ip_on_launch=true`.
- **Private subnets** across three availability zones:
  - `us-east-1a` → `10.0.101.0/24`
  - `us-east-1b` → `10.0.102.0/24`
  - `us-east-1c` → `10.0.103.0/24`
  - Tagged `Tier=private`.
- **Single NAT Gateway** (with an Elastic IP) in the first public subnet
  (`us-east-1a`) that serves all private subnets. A single NAT is used to
  minimize cost (~$12/month incremental). For high availability you would need
  one NAT per AZ, which triples the cost.
- **Public route table** with a `0.0.0.0/0` route to the Internet Gateway,
  associated with all public subnets.
- **Private route table** with a `0.0.0.0/0` route to the NAT Gateway,
  associated with all private subnets.
- **Security groups** (least-privilege baseline):
  - `Pulsar-bastion-sg`: SSH (22) from `bastion_allowed_cidr`.
  - `Pulsar-app-sg`: app ports (`app_ports`, default `8080`, `443`) from the VPC
    CIDR, and HTTPS egress to `0.0.0.0/0`.
  - `Pulsar-db-sg`: database port (`db_port`, default `5432`) from the app
    security group, with no outbound internet access.

### Tagging

All resources are tagged with `Environment`, `Project`, and `ManagedBy` for cost
allocation and tracking. The `default_tags` variable is applied as provider-level
default tags, and `Environment` defaults to `pulsar`.

### Important: Replace the Bastion CIDR Placeholder

The `bastion_allowed_cidr` variable defaults to `0.0.0.0/0` as a placeholder.
**Replace this with your office IP range** (e.g., `203.0.113.0/24`) before
applying to real infrastructure. Leaving it wide open allows SSH from anywhere,
which is a security risk.

### Notes

- Before managing real infrastructure, plan to configure a remote backend
  (e.g., S3 + DynamoDB) to avoid state loss or conflicts.
- The VPC CIDR and subnet sizes are fixed. Plan for future expansion if the
  platform grows beyond the available IP space.
- To roll back, delete the NAT gateway, IGW, route tables, subnets, and finally
  the VPC. This disrupts any running workloads in the VPC.
