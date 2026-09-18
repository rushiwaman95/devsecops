# Budget Module
# AWS Budget and cost alerts for cost optimization

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 500
}

variable "budget_alert_threshold" {
  description = "Percentage threshold for budget alert"
  type        = number
  default     = 80
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# SNS Topic for Budget Notifications
resource "aws_sns_topic" "budget_alerts" {
  name_prefix = "${var.project_name}-budget-alerts-"

  tags = local.common_tags
}

# Budget
resource "aws_budgets_budget" "main" {
  name              = "${var.project_name}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.budget_amount
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  cost_filter {
    name = "TagKeyValue"
    values = [
      "user:Project${var.project_name}"
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.budget_alert_threshold
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [] # Add team email addresses here
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [] # Add team email addresses here
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [] # Add team email addresses here
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }
}

# Outputs
output "budget_arn" {
  description = "ARN of the budget"
  value       = aws_budgets_budget.main.arn
}

output "budget_name" {
  description = "Name of the budget"
  value       = aws_budgets_budget.main.name
}

output "budget_alerts_topic_arn" {
  description = "ARN of SNS topic for budget alerts"
  value       = aws_sns_topic.budget_alerts.arn
}
