# Main Terraform Configuration for SaaS Application
# This file orchestrates all modules to create production-ready infrastructure

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Backend configuration for state management (uncomment for production)
  # backend "s3" {
  #   bucket         = "terraform-state-bucket-saas-app"
  #   key            = "saas-app/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Owner       = var.owner
  }
}

# ============================================
# VPC Module
# ============================================
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
}

# ============================================
# Security Groups Module
# ============================================
module "security" {
  source = "./modules/security"

  project_name             = var.project_name
  environment              = var.environment
  vpc_id                   = module.vpc.vpc_id
  alb_sg_ingress_cidrs     = var.alb_allowed_cidrs
}

# ============================================
# Application Load Balancer Module
# ============================================
module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id

  ssl_certificate_arn = var.ssl_certificate_arn
  target_port         = 80
  health_check_path   = "/health"
}

# ============================================
# Auto Scaling Group Module
# ============================================
module "asg" {
  source = "./modules/asg"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ec2_security_group_id = module.security.ec2_security_group_id
  target_group_arn      = module.alb.target_group_arn

  instance_type    = var.instance_type
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  ebs_encrypted     = true
  enable_monitoring = true

  # User data script for NGINX setup
  user_data = <<-EOF
#!/bin/bash
set -e

# Update and install packages
yum update -y
yum install -y nginx docker git amazon-cloudwatch-agent

# Start Docker
systemctl start docker
systemctl enable docker

# Create sample application content
mkdir -p /usr/share/nginx/html

# Health check endpoint
cat > /usr/share/nginx/html/health << 'HEALTH'
{"status": "healthy", "timestamp": "${timestamp("utc")}"}
HEALTH

# Main page
cat > /usr/share/nginx/html/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head><title>SaaS Application</title></head>
<body>
<h1>Welcome to SaaS Application</h1>
<p>Application is running successfully!</p>
<p>Environment: ${var.environment}</p>
</body>
</html>
HTML

# Configure NGINX health endpoint
cat > /etc/nginx/conf.d/health.conf << 'NGINX'
location /health {
    alias /usr/share/nginx/html/health;
    default_type application/json;
}
NGINX

# Start NGINX
systemctl start nginx
systemctl enable nginx

# Configure CloudWatch Agent for logs
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/aws/ec2/${var.project_name}/nginx-access",
            "log_stream_name": "{instance_id}/nginx-access",
            "timestamp_format": "%d/%b/%Y:%H:%M:%S %z"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/aws/ec2/${var.project_name}/nginx-error",
            "log_stream_name": "{instance_id}/nginx-error",
            "timestamp_format": "%Y/%m/%d %H:%M:%S"
          }
        ]
      }
    }
  }
}
CWCONFIG

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

EOF
}

# ============================================
# Monitoring Module
# ============================================
module "monitoring" {
  source = "./modules/monitoring"

  project_name = var.project_name
  environment  = var.environment
  asg_name     = module.asg.asg_name
  alb_arn      = module.alb.alb_arn

  cpu_threshold            = var.cpu_alarm_threshold
  alarm_evaluation_periods = 2
  alarm_period             = 300
}

# ============================================
# Budget Module
# ============================================
module "budget" {
  source = "./modules/budget"

  project_name           = var.project_name
  environment            = var.environment
  budget_amount          = var.budget_amount
  budget_alert_threshold = var.budget_alert_threshold
}

# ============================================
# S3 Bucket with Block Public Access
# ============================================
resource "aws_s3_bucket" "application" {
  bucket_prefix = "${var.project_name}-"

  tags = local.common_tags
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "application" {
  bucket = aws_s3_bucket.application.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "application" {
  bucket = aws_s3_bucket.application.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "application" {
  bucket = aws_s3_bucket.application.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ============================================
# ACM Certificate for HTTPS (if domain is provided)
# ============================================
resource "aws_acm_certificate" "main" {
  count = var.domain_name != "" ? 1 : 0

  domain_name               = var.domain_name
  validation_method         = "DNS"
  subject_alternative_names = var.subject_alternative_names

  lifecycle {
    create_before_destroy = true
  }

  tags = local.common_tags
}

# DNS validation records (to be created in Route53)
resource "aws_route53_record" "cert_validation" {
  for_each = var.domain_name != "" ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

# Certificate validation resource
resource "aws_acm_certificate_validation" "main" {
  count = var.domain_name != "" ? 1 : 0

  certificate_arn         = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ============================================
# Outputs
# ============================================
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.asg.asg_name
}

output "ec2_iam_role_arn" {
  description = "ARN of EC2 IAM role"
  value       = module.asg.ec2_iam_role_arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.application.bucket
}

output "high_cpu_alarm_arn" {
  description = "ARN of high CPU alarm"
  value       = module.monitoring.high_cpu_alarm_arn
}

output "unhealthy_hosts_alarm_arn" {
  description = "ARN of unhealthy hosts alarm"
  value       = module.monitoring.unhealthy_hosts_alarm_arn
}

output "cloudwatch_dashboard_name" {
  description = "Name of CloudWatch dashboard"
  value       = module.monitoring.dashboard_name
}

output "budget_name" {
  description = "Name of the budget"
  value       = module.budget.budget_name
}

output "certificate_arn" {
  description = "ARN of ACM certificate (if created)"
  value       = try(aws_acm_certificate.main[0].arn, null)
}
