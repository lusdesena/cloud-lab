resource "aws_budgets_budget" "monthly" {
  name              = "cloud-lab-monthly"
  budget_type       = "COST"
  time_unit         = "MONTHLY"
  limit_amount      = "20.0"
  limit_unit        = "USD"
  time_period_start = "2026-10-01_00:00"
  metrics = ["UnblendedCost"]
  billing_view_arn = "arn:aws:billing::${data.aws_caller_identity.current.account_id}:billingview/primary"

  filter_expression {
    dimensions {
      key = "RECORD_TYPE"
      values = ["Other", "Upfront", "Support", "Recurring", "Usage", "Tax"]
    }
  }

  notification {
    notification_type          = "ACTUAL"
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = var.budget_emails
  }
  notification {
    notification_type          = "ACTUAL"
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = var.budget_emails
  }
  notification {
    notification_type          = "FORECASTED"
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = var.budget_emails
  }
}