# Monitoring Module
# CloudWatch logs, metrics, and alarms for CPU and instance health

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group name"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string
}

variable "cpu_threshold" {
  description = "CPU utilization threshold for alarm (percentage)"
  type        = number
  default     = 70
}

variable "alarm_evaluation_periods" {
  description = "Number of periods to evaluate for alarm"
  type        = number
  default     = 2
}

variable "alarm_period" {
  description = "Period in seconds for alarm evaluation"
  type        = number
  default     = 300
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# CloudWatch Log Group for Application Logs
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/ec2/${var.project_name}/application"
  retention_in_days = 30

  tags = local.common_tags
}

# CloudWatch Log Group for NGINX Access Logs
resource "aws_cloudwatch_log_group" "nginx_access" {
  name              = "/aws/ec2/${var.project_name}/nginx-access"
  retention_in_days = 14

  tags = local.common_tags
}

# CloudWatch Log Group for NGINX Error Logs
resource "aws_cloudwatch_log_group" "nginx_error" {
  name              = "/aws/ec2/${var.project_name}/nginx-error"
  retention_in_days = 14

  tags = local.common_tags
}

# CloudWatch Alarm for High CPU Utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "This alarm monitors EC2 CPU utilization. Triggers when average CPU >= ${var.cpu_threshold}% for ${var.alarm_evaluation_periods * var.alarm_period / 60} minutes."
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

# CloudWatch Alarm for Unhealthy Host Count
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.project_name}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "This alarm monitors unhealthy host count. Triggers when any host is unhealthy."
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = split("/", var.alb_arn)[1]
    LoadBalancer = split("/", var.alb_arn)[1]
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

# CloudWatch Alarm for Request Count (for monitoring traffic)
resource "aws_cloudwatch_metric_alarm" "low_request_count" {
  alarm_name          = "${var.project_name}-low-request-count"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "This alarm monitors request count. Triggers when requests are unusually low."
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = split("/", var.alb_arn)[1]
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name_prefix = "${var.project_name}-alerts-"

  tags = local.common_tags
}

# SNS Topic Policy for encryption
resource "aws_sns_topic_policy" "alerts" {
  arn    = aws_sns_topic.alerts.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:cloudwatch:*:*:alarm:${var.project_name}-*"
          }
        }
      }
    ]
  })
}

# Dashboard for monitoring
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "EC2 CPU Utilization"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name, { stat = "Average", period = 300 }]
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "ALB Request Count"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", split("/", var.alb_arn)[1], { stat = "Sum", period = 300 }]
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "Unhealthy Host Count"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", split("/", var.alb_arn)[1], { stat = "Average", period = 300 }]
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "Network In/Out"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", var.asg_name, { stat = "Average", period = 300 }],
            [".", "NetworkOut", ".", ".", { stat = "Average", period = 300 }]
          ]
          view = "timeSeries"
        }
      }
    ]
  })
}

# Data source for current region
data "aws_region" "current" {}

# Outputs
output "application_log_group_name" {
  description = "Name of application log group"
  value       = aws_cloudwatch_log_group.application.name
}

output "nginx_access_log_group_name" {
  description = "Name of NGINX access log group"
  value       = aws_cloudwatch_log_group.nginx_access.name
}

output "nginx_error_log_group_name" {
  description = "Name of NGINX error log group"
  value       = aws_cloudwatch_log_group.nginx_error.name
}

output "high_cpu_alarm_arn" {
  description = "ARN of high CPU alarm"
  value       = aws_cloudwatch_metric_alarm.high_cpu.arn
}

output "unhealthy_hosts_alarm_arn" {
  description = "ARN of unhealthy hosts alarm"
  value       = aws_cloudwatch_metric_alarm.unhealthy_hosts.arn
}

output "sns_topic_arn" {
  description = "ARN of SNS alerts topic"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  description = "Name of CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}
