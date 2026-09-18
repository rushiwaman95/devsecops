# Outputs for SaaS Application Infrastructure

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

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.application.arn
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

output "sns_topic_arn" {
  description = "ARN of SNS topic for alerts"
  value       = module.monitoring.sns_topic_arn
}

output "certificate_arn" {
  description = "ARN of ACM certificate (if created)"
  value       = try(aws_acm_certificate.main[0].arn, null)
}

output "application_log_group_name" {
  description = "Name of application log group"
  value       = module.monitoring.application_log_group_name
}

output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = module.security.alb_security_group_id
}

output "ec2_security_group_id" {
  description = "Security group ID for EC2 instances"
  value       = module.security.ec2_security_group_id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.nat_gateway_ids
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}
