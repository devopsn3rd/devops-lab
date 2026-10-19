variable "project" {
  description = "Short project name used as a prefix for every resource."
  type        = string
}

variable "environment" {
  description = "Environment name (devel or stage)."
  type        = string
}

variable "price_class" {
  description = "CloudFront price class. PriceClass_100 = cheapest (NA + Europe edges)."
  type        = string
  default     = "PriceClass_100"
}

variable "log_retention_days" {
  description = "Days to keep CloudFront access logs."
  type        = number
  default     = 30
}
