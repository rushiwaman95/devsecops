# SaaS Application AWS Infrastructure

[![Terraform](https://img.shields.io/badge/Terraform-1.6+-blue)](https://www.terraform.io)
[![AWS](https://img.shields.io/badge/AWS-Production-orange)](https://aws.amazon.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

A production-ready, highly available, secure, and cost-optimized AWS infrastructure for a SaaS web application, provisioned entirely with Terraform.

## 📖 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Deployment Steps](#deployment-steps)
- [Architecture Decisions](#architecture-decisions)
- [Cost Estimate](#cost-estimate)
- [Security Measures](#security-measures)
- [Scaling Strategy](#scaling-strategy)
- [Monitoring & Observability](#monitoring--observability)
- [CI/CD Pipeline](#cicd-pipeline)
- [Production Readiness](#production-readiness)

---

## 🏗 Architecture Overview

```
                                    ┌─────────────────────────────────────────────────────────────┐
                                    │                        AWS Cloud (us-east-1)                 │
                                    │                                                              │
┌──────────┐    HTTPS               │   ┌──────────────────────────────────────────────────────┐   │
│  Users   │ ──────────────────────►│   │              Public Subnet (AZ-a)                     │   │
└──────────┘                        │   │                                                       │   │
                                    │   │  ┌─────────────────┐                                 │   │
                                    │   │  │   Internet      │                                 │   │
                                    │   │  │    Gateway      │                                 │   │
                                    │   │  └────────┬────────┘                                 │   │
                                    │   │           │                                          │   │
                                    │   │  ┌────────▼────────┐    ┌──────────────────┐         │   │
                                    │   │  │  ALB (Public)   │    │   NAT Gateway    │         │   │
                                    │   │  │  Port 443/80    │    │                  │         │   │
                                    │   │  └────────┬────────┘    └─────────▲────────┘         │   │
                                    │   │           │                       │                   │   │
                                    │   └───────────┼───────────────────────┼───────────────────┘   │
                                    │               │                       │                       │
                                    │   ┌───────────▼───────────────────────▼───────────────────┐   │
                                    │   │              Private Subnet (AZ-a)                     │   │
                                    │   │                                                       │   │
                                    │   │  ┌─────────────────────────────────────────────────┐   │   │
                                    │   │  │              EC2 Instances (ASG)                │   │   │
                                    │   │  │  - NGINX Web Server                             │   │   │
                                    │   │  │  - Min: 2, Max: 4                             │   │   │
                                    │   │  │  - Health Check: /health                      │   │   │
                                    │   │  │  - IAM Role (No static keys)                  │   │   │
                                    │   │  │  - Encrypted EBS (gp3)                        │   │   │
                                    │   │  └─────────────────────────────────────────────────┘   │   │
                                    │   │                                                       │   │
                                    │   │  ┌─────────────────┐    ┌──────────────────┐          │   │
                                    │   │  │  CloudWatch     │    │       S3         │          │   │
                                    │   │  │  Logs & Alarms  │    │  (Block Public)  │          │   │
                                    │   │  └─────────────────┘    └──────────────────┘          │   │
                                    │   │                                                       │   │
                                    │   └───────────────────────────────────────────────────────┘   │
                                    │                                                              │
                                    │   ┌──────────────────────────────────────────────────────┐   │
                                    │   │              Private Subnet (AZ-b)                    │   │
                                    │   │  (Same configuration as AZ-a for HA)                 │   │
                                    │   └──────────────────────────────────────────────────────┘   │
                                    │                                                              │
                                    └─────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Description | High Availability |
|-----------|-------------|-------------------|
| **VPC** | Isolated network (10.0.0.0/16) | 2 AZs |
| **Public Subnets** | ALB, NAT Gateway | 2 subnets |
| **Private Subnets** | EC2 instances, databases | 2 subnets |
| **ALB** | Application Load Balancer with HTTPS | Multi-AZ |
| **Auto Scaling Group** | EC2 instances (min 2, max 4) | Multi-AZ |
| **NAT Gateway** | Outbound internet for private subnets | Single (configurable) |
| **S3** | Object storage with encryption | Regional |

---

## ✨ Features

### Infrastructure (Terraform)
- ✅ VPC with 2 Availability Zones
- ✅ 2 Public Subnets + 2 Private Subnets
- ✅ Internet Gateway
- ✅ NAT Gateway (single for cost optimization, configurable for HA)
- ✅ Route Tables (public & private)
- ✅ Security Groups (least privilege model)

### Application Layer
- ✅ Application Load Balancer (ALB)
- ✅ Auto Scaling Group (minimum 2 instances)
- ✅ EC2 instances in private subnets only
- ✅ NGINX with health check endpoint
- ✅ Health checks configured on ALB

### Observability
- ✅ CloudWatch Logs enabled (application, nginx access/error)
- ✅ Basic metrics monitoring (CPU, network, requests)
- ✅ Alarm on high CPU usage (>70%)
- ✅ Alarm on unhealthy host count
- ✅ CloudWatch Dashboard

### Security Controls
- ✅ No public EC2 instances (all in private subnets)
- ✅ S3 Block Public Access enabled
- ✅ IAM Roles for EC2 (no static access keys)
- ✅ Encrypted EBS volumes (AES-256)
- ✅ HTTPS listener on ALB (with ACM certificate)
- ✅ No secrets committed in repository
- ✅ IMDSv2 required on EC2
- ✅ Security groups with least privilege

### Cost Awareness
- ✅ Budget alert configured
- ✅ Cost optimization recommendations included
- ✅ Single NAT Gateway option for non-prod

---

## 🛠 Prerequisites

Before deploying this infrastructure, ensure you have:

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.5.0 installed
3. **AWS CLI** configured with credentials
4. **Git** for version control

### Required AWS Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "cloudwatch:*",
        "s3:*",
        "sns:*",
        "logs:*",
        "iam:CreateRole",
        "iam:CreatePolicy",
        "iam:AttachRolePolicy"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 🚀 Deployment Steps

### 1. Clone the Repository
```bash
git clone <repository-url>
cd terraform
```

### 2. Configure Backend (Optional but Recommended)
Uncomment the backend configuration in `main_saas.tf`:
```hcl
backend "s3" {
  bucket         = "terraform-state-bucket-saas-app"
  key            = "saas-app/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-locks"
}
```

Create the S3 bucket and DynamoDB table:
```bash
aws s3 mb s3://terraform-state-bucket-saas-app
aws dynamodb create-table --table-name terraform-locks --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST
```

### 3. Initialize Terraform
```bash
cd terraform
terraform init
```

### 4. Create tfvars File (Optional)
```bash
cat > production.tfvars << EOF
environment        = "prod"
project_name       = "my-saas-app"
instance_type      = "t3.medium"
min_size           = 2
max_size           = 4
desired_capacity   = 2
ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789:certificate/xxx"
domain_name        = "app.example.com"
budget_amount      = 500
EOF
```

### 5. Plan and Apply
```bash
# Review the plan
terraform plan -var-file=production.tfvars

# Deploy infrastructure
terraform apply -var-file=production.tfvars
```

### 6. Verify Deployment
```bash
# Get ALB DNS name
export ALB_DNS=$(terraform output -raw alb_dns_name)

# Test health endpoint
curl -k https://${ALB_DNS}/health

# Check ASG status
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $(terraform output -raw asg_name)
```

---

## 🏛 Architecture Decisions

### 1. VPC Design
| Decision | Rationale |
|----------|-----------|
| **2 AZs** | Balances high availability with cost. More AZs increase complexity and cost. |
| **/16 CIDR** | Provides ample IP space for growth while staying within best practices. |
| **Separate public/private subnets** | Security isolation; EC2 instances never directly exposed to internet. |

### 2. Compute Strategy
| Decision | Rationale |
|----------|-----------|
| **EC2 with ASG** | Simpler than ECS/EKS for basic web apps; full control over OS. |
| **t3.medium instance type** | Good balance of compute/memory for typical web workloads. |
| **Min 2 instances** | Ensures high availability even during AZ failure or rolling updates. |

### 3. Load Balancing
| Decision | Rationale |
|----------|-----------|
| **ALB over NLB** | Layer 7 routing, health checks, SSL termination at load balancer. |
| **HTTPS redirect** | Enforces encrypted connections for all traffic. |

### 4. Security
| Decision | Rationale |
|----------|-----------|
| **IAM Roles (not keys)** | Eliminates risk of credential leakage; automatic rotation. |
| **Encrypted EBS** | Protects data at rest; minimal performance impact with gp3. |
| **IMDSv2 required** | Prevents SSRF attacks from accessing instance metadata. |

### 5. Cost Optimization
| Decision | Rationale |
|----------|-----------|
| **Single NAT Gateway** | Saves ~$32/month vs. multi-AZ NAT for non-critical workloads. |
| **t3 instances** | Burstable performance suitable for variable workloads. |
| **CloudWatch log retention** | 14-30 days balances debugging needs with storage costs. |

---

## 💰 Cost Estimate

### Monthly Cost Breakdown (us-east-1)

| Resource | Quantity | Unit Price | Monthly Cost |
|----------|----------|------------|--------------|
| **VPC** | 1 | Free | $0.00 |
| **Internet Gateway** | 1 | Free | $0.00 |
| **NAT Gateway** | 1 | $0.045/hr + $0.045/GB | ~$35.00* |
| **Application Load Balancer** | 1 | $0.0225/hr + LCU charges | ~$25.00 |
| **EC2 Instances (t3.medium)** | 2 | $0.0416/hr each | ~$60.00 |
| **EBS Volumes (gp3, 20GB)** | 2 | $0.08/GB-month | ~$3.20 |
| **CloudWatch Logs** | ~1GB/month | $0.50/GB ingested | ~$0.50 |
| **CloudWatch Alarms** | 3 | $0.10/alarm-month | ~$0.30 |
| **CloudWatch Dashboard** | 1 | Free (first 3) | $0.00 |
| **SNS Topic** | 1 | Free (first 1M pub) | ~$0.00 |
| **S3 Bucket** | 1 | $0.023/GB-month | ~$0.50** |
| **Budget** | 1 | Free | $0.00 |
| **Data Transfer** | Variable | $0.09/GB out | ~$10.00*** |

**Total Estimated Monthly Cost: ~$134.50**

\* NAT Gateway costs vary based on data processed
\** Assumes minimal S3 usage
\*\*\* Assumes ~100GB outbound data transfer

### Cost Optimization Recommendations

1. **Use Graviton Instances (M6g/T4g)**
   - 20% better price-performance than t3
   - Potential savings: ~$12/month

2. **Savings Plans**
   - 1-year Compute Savings Plan: ~30% discount
   - Potential savings: ~$18/month on EC2

3. **Right-sizing**
   - Monitor CloudWatch metrics for first 2 weeks
   - Downgrade to t3.small if CPU < 40% consistently
   - Potential savings: ~$30/month

4. **Multi-AZ NAT Gateway (for Production)**
   - Add second NAT Gateway for HA: +$35/month
   - Recommended for production workloads

5. **Spot Instances for Stateless Workloads**
   - Up to 70% discount for fault-tolerant workloads
   - Not recommended for minimum capacity

---

## 🔒 Security Measures

### Network Security
- **Security Groups**: Least privilege ingress rules
  - ALB: Only ports 80/443 from 0.0.0.0/0
  - EC2: Only port 80 from ALB security group
- **No Public IPs on EC2**: All instances in private subnets
- **VPC Flow Logs**: Enabled for network traffic analysis

### Identity & Access
- **IAM Roles**: Attached to EC2 via instance profile
- **No Static Credentials**: No access keys in code or user data
- **Managed Policies**: Using AWS managed policies where possible

### Data Protection
- **EBS Encryption**: All volumes encrypted with AWS-managed KMS
- **S3 Encryption**: SSE-S3 enabled, block public access
- **SSL/TLS**: HTTPS enforced on ALB with TLS 1.3

### Instance Security
- **IMDSv2**: Required (prevents SSRF attacks)
- **SSM Session Manager**: For secure shell access (no SSH keys)
- **Automatic Updates**: Configured via user data script

### Compliance
- **No Secrets in Code**: Scanned in CI/CD pipeline
- **Infrastructure as Code**: All changes auditable via Git
- **Tagging Strategy**: Consistent tags for cost allocation and compliance

---

## 📈 Scaling Strategy

### Horizontal Scaling (Auto Scaling)

| Metric | Threshold | Action |
|--------|-----------|--------|
| **CPU Utilization** | > 70% for 5 min | Scale out (+1 instance) |
| **CPU Utilization** | < 30% for 10 min | Scale in (-1 instance) |
| **Request Count** | > 1000/min | Scale out (+1 instance) |

### Scaling Configuration
```hcl
min_size         = 2  # Always maintain 2 for HA
max_size         = 4  # Cap to control costs
desired_capacity = 2  # Start with minimum
cooldown         = 300 seconds
```

### Vertical Scaling Options
- **Instance Type**: Upgrade from t3.medium to t3.large or m5.large
- **When to scale up**: Consistent CPU > 80% with max instances running

### Disaster Recovery
- **Multi-AZ deployment**: Survives single AZ failure
- **Backup Strategy**: 
  - AMI creation via Lambda (weekly)
  - S3 versioning enabled
- **RTO**: ~10 minutes (ASG replacement)
- **RPO**: ~1 week (AMI backup frequency)

---

## 📊 Monitoring & Observability

### CloudWatch Metrics
- **EC2**: CPU, Network In/Out, Disk Read/Write
- **ALB**: Request Count, Target Response Time, UnHealthyHostCount
- **ASG**: GroupDesiredCapacity, GroupInServiceInstances

### CloudWatch Alarms
| Alarm Name | Metric | Threshold | Action |
|------------|--------|-----------|--------|
| `high-cpu-utilization` | CPUUtilization | >= 70% | SNS notification |
| `unhealthy-hosts` | UnHealthyHostCount | > 0 | SNS notification |
| `low-request-count` | RequestCount | < 100 | SNS notification |

### CloudWatch Dashboard
Pre-built dashboard includes:
- EC2 CPU Utilization (average)
- ALB Request Count (sum)
- Unhealthy Host Count
- Network In/Out

### Log Groups
- `/aws/ec2/{project}/application` - Application logs (30 days)
- `/aws/ec2/{project}/nginx-access` - NGINX access logs (14 days)
- `/aws/ec2/{project}/nginx-error` - NGINX error logs (14 days)

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

The pipeline includes:

1. **Security Scan**
   - Secret detection (grep patterns)
   - Trivy filesystem scan

2. **Terraform Validate**
   - Format check (`terraform fmt`)
   - Initialization (`terraform init`)
   - Validation (`terraform validate`)

3. **Terraform Plan** (PR only)
   - Generates execution plan
   - Comments on PR with results

4. **Cost Estimation** (PR only)
   - Uses Infracost for cost breakdown

5. **Terraform Apply** (main branch only)
   - Requires production environment approval
   - Applies infrastructure changes

### Required Secrets
```bash
# In GitHub Settings > Secrets and variables > Actions
AWS_ROLE_ARN=arn:aws:iam::ACCOUNT_ID:role/github-actions-role
```

---

## ✅ Production Readiness Checklist

### Pre-Deployment
- [ ] Terraform state backend configured (S3 + DynamoDB)
- [ ] AWS credentials configured with least privilege
- [ ] SSL certificate obtained (ACM)
- [ ] Domain name configured (Route53)
- [ ] Budget alerts configured with team email

### Security
- [ ] No hardcoded secrets in codebase
- [ ] Security groups follow least privilege
- [ ] IMDSv2 enforced on all instances
- [ ] EBS encryption enabled
- [ ] S3 block public access enabled

### High Availability
- [ ] Resources distributed across 2+ AZs
- [ ] Minimum 2 instances in ASG
- [ ] ALB health checks configured
- [ ] NAT Gateway redundancy considered (for prod)

### Monitoring
- [ ] CloudWatch alarms configured
- [ ] SNS topic subscribed by on-call team
- [ ] Dashboard created and shared
- [ ] Log retention policies set

### Cost Management
- [ ] Budget alerts configured
- [ ] Tags applied for cost allocation
- [ ] Right-sizing plan documented
- [ ] Savings Plans evaluated

### Documentation
- [ ] Runbook created for common issues
- [ ] Escalation procedures defined
- [ ] Contact information updated
- [ ] Architecture diagram current

---

## 📁 Repository Structure

```
/workspace
├── terraform/
│   ├── main_saas.tf           # Main orchestration file
│   ├── variables_saas.tf      # Input variables
│   ├── modules/
│   │   ├── vpc/               # VPC module
│   │   ├── security/          # Security groups
│   │   ├── alb/               # Load balancer
│   │   ├── asg/               # Auto Scaling Group
│   │   ├── monitoring/        # CloudWatch resources
│   │   └── budget/            # Budget alerts
│   └── outputs_saas.tf        # Output values
├── .github/workflows/
│   └── terraform-cicd.yml     # CI/CD pipeline
├── app/
│   └── Dockerfile             # Application container
├── docs/
│   └── architecture.png       # Architecture diagram
└── README.md                  # This file
```

---

## 🆘 Troubleshooting

### Common Issues

1. **Terraform Init Fails**
   ```bash
   # Clear cache and retry
   rm -rf .terraform/
   terraform init -reconfigure
   ```

2. **ALB Health Checks Failing**
   - Verify NGINX is running: `systemctl status nginx`
   - Check health endpoint: `curl localhost/health`
   - Review security group rules

3. **EC2 Instances Not Launching**
   - Check IAM role permissions
   - Verify subnet has available IPs
   - Review ASG activity history: `aws autoscaling describe-scaling-activities`

---

## 📞 Support

For issues or questions:
- Open a GitHub issue
- Contact: cloud-team@example.com

---

**Built with ❤️ using Terraform and AWS Best Practices**
