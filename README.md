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

> **Note:** The `bastion_allowed_cidr` variable has no default and **must be
> provided** (e.g., via `-var`, a `.tfvars` file, or environment variables).
> `terraform plan`/`apply` will fail until it is set. See
> [Important: Set the Bastion CIDR](#important-set-the-bastion-cidr) below.
>
> **Note:** The `certificate_arn` variable also has no default and **must be
> provided** before applying. See
> [Important: Set the Web Certificate ARN](#important-set-the-web-certificate-arn)
> below.
>
> **Note:** The `web_alb_ingress_cidrs` variable also has no default and **must
> be provided** before applying. See
> [Important: Set the Web ALB Ingress CIDRs](#important-set-the-web-alb-ingress-cidrs)
> below.

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
    security group. Egress is explicitly restricted to the VPC CIDR only, so
    the database tier has **no outbound internet access**.

### Tagging

All resources are tagged with `Environment`, `Project`, and `ManagedBy` for cost
allocation and tracking. The `default_tags` variable is applied as provider-level
default tags, and `Environment` defaults to `pulsar`.

### Important: Set the Bastion CIDR

The `bastion_allowed_cidr` variable has **no default** and must be set explicitly
to your office IP range (e.g., `203.0.113.0/24`) or a bastion host CIDR. It is
deliberately not defaulted to `0.0.0.0/0`, which would open SSH to the entire
internet. `terraform plan`/`apply` will fail until you provide a value.

## Web Tier

The configuration provisions the horizontally scalable EC2 web tier via the
`modules/web` module. It deploys an internet-facing Application Load Balancer
(ALB) in front of an Auto Scaling Group (ASG) running across the three private
subnets.

### Architecture

- The **internet-facing ALB** is placed in the **public subnets** (which have a
  route to the Internet Gateway) so it is reachable from the internet. It
  terminates TLS on port 443.
- The **ASG instances** run in the **private subnets** (egress via the NAT
  Gateway). The ALB forwards plain HTTP on port 80 to the instances, which run
  `httpd` — so the target group and health check use HTTP:80 and the web
  security group opens port 80 to the ALB security group only.

### Resources Created

- **Launch template** (`pulsar-web-launch-template`): selects the latest Amazon
  Linux 2 HVM x86_64 AMI owned by `amazon`, uses `t3.small` instances, attaches
  the web security group, and runs a bootstrap script that installs and starts
  `httpd` and serves a simple `/health` response page. The ASG references the
  template's **`$Default`** version so launch template changes are reviewed
  before being applied to new instances.
- **Security groups**:
  - `pulsar-alb-sg`: allows HTTPS (443) inbound from `web_alb_ingress_cidrs`
    (required, no default) and all egress.
  - `pulsar-web-sg`: allows HTTP (80) inbound from `pulsar-alb-sg` only and all
    egress.
- **Target group** (`pulsar-web-tg`): type `instance`, HTTP on port 80, with a
  health check on `health_check_path` (default `/health`).
- **Application Load Balancer** (`pulsar-web-alb`): internet-facing, IPv4,
  attached to the three **public subnets**, with `enable_deletion_protection =
  true`, ALB access logs delivered to a private S3 bucket, and an HTTPS:443
  listener forwarding to `pulsar-web-tg`.
- **ALB access-log S3 bucket** (`pulsar-web-alb-access-logs-<account>-<env>`):
  private, blocks all public access, grants the ELB service account and log
  delivery service write access, and expires logs after 90 days.
- **Auto Scaling Group** (`pulsar-web-asg`): launch template referenced, ELB
  health checks, desired `2` / min `2` / max `6`, attached to the target group.
- **Target tracking scaling policy**: scales on average CPU utilization at
  `web_cpu_target_value` (default 60%) between the min and max sizes.

### Important: Set the Web Certificate ARN

The web ALB uses an HTTPS listener, which **requires a valid SSL/TLS
certificate**. The `certificate_arn` variable has **no default** and must be set
before applying. Request a certificate via AWS Certificate Manager (ACM) for
your domain and pass its ARN, e.g.:

```bash
terraform apply -var="certificate_arn=arn:aws:acm:us-east-1:463737305712:certificate/xxxx"
```

`terraform plan`/`apply` will fail until this is provided.

### Important: Set the Web ALB Ingress CIDRs

The web ALB is **internet-facing**, and the `web_alb_ingress_cidrs` variable has
**no default** and must be set before applying. It scopes which source CIDRs may
reach the ALB on HTTPS:

- Use `["0.0.0.0/0"]` **only** if the web app is genuinely public.
- Otherwise restrict it to the required ranges (e.g., your office/partner
  CIDRs).

It is deliberately not defaulted to a wide-open range without an explicit
decision. Example:

```bash
terraform apply \
  -var="web_alb_ingress_cidrs=[\"0.0.0.0/0\"]"
```

`terraform plan`/`apply` will fail until this is provided.

### Usage & Verification

After applying, verify the deployment:

- Check the ASG is launching and passing health checks:
  - `terraform output asg_id` and inspect the ASG in the console.
- Confirm instances are healthy in the target group:
  - `terraform output target_group_arn` and inspect the `pulsar-web-tg` Targets
    tab in the console.
- Browse to the ALB DNS name (expect the web server default page or your app):
  - `terraform output alb_dns_name`
- ALB access logs are written to the `pulsar-web-alb-access-logs-*` S3 bucket
  under the `alb/` prefix.

### Rollback

To roll back the web tier, delete the ASG (instances terminate), then the ALB,
target group, and launch template. In Terraform, run `terraform destroy` (or
remove the `module "web"` block and apply). This does not affect the network
layer or any data.

## Security Logging

The configuration hardens the Pulsar platform's audit and network visibility via
the `modules/security_logging` module. It provisions an encrypted, private S3
bucket for security logs, a multi-region CloudTrail trail with log file
validation, and VPC Flow Logs for the Pulsar VPC.

### Resources Created

- **Security log S3 bucket** (`pulsar-security-logs-<account>`): private,
  blocks all public access, server-side encrypted with SSE-S3 (AES256), and
  expires logs after `log_retention_days` (default 2557 days / 7 years) via a
  lifecycle rule.
- **Bucket policy**: allows only `cloudtrail.amazonaws.com` to write to the
  `AWSLogs/<account>/*` prefix and `vpc-flow-logs.amazonaws.com` to write to the
  `vpc-flow-logs/*` prefix (with `GetBucketAcl` and `PutObject`). No public
  read/write access is granted.
- **CloudTrail trail** (`pulsar-security-trail`): multi-region
  (`is_multi_region_trail = true`), log file validation enabled, includes global
  service events, and delivers to the security log bucket.
- **VPC Flow Logs** (`pulsar-flow-log-<vpc>`): one per VPC in `vpc_ids`, with
  `traffic_type = ALL`, `max_aggregation_interval = 600` (10 minutes), delivered
  to the security log bucket in `plain-text` format with per-hour partitioning.

### Security Group Note

The existing security groups already restrict inbound access to least-privilege —
there are **no `0.0.0.0/0` inbound rules** on the bastion, app, or database
security groups. Consequently, no security group changes are required for this
hardening effort.

### Verification

- CloudTrail: confirm the `pulsar-security-trail` status is **Logging** and shows
  **Multi-region: Yes**.
- S3: confirm **Block all public access** is on and encryption (SSE-S3) is
  enabled on the security log bucket.
- VPC Flow Logs: confirm the flow log status is **Active** for the Pulsar VPC.
- After 5–15 minutes, check the bucket for new objects under the `AWSLogs/` and
  `vpc-flow-logs/` prefixes.

### Rollback

To roll back security logging, delete the flow logs, delete the CloudTrail trail,
and remove the bucket policy. The S3 bucket can be emptied and deleted after the
required retention period (or the lifecycle rule can be adjusted).

### Notes

- Before managing real infrastructure, plan to configure a remote backend
  (e.g., S3 + DynamoDB) to avoid state loss or conflicts.
- The VPC CIDR and subnet sizes are fixed. Plan for future expansion if the
  platform grows beyond the available IP space.
- To roll back the network layer, delete the NAT gateway, IGW, route tables,
  subnets, and finally the VPC. This disrupts any running workloads in the VPC.
