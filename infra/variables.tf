variable "aws_region" {
  description = "AWS region for the S3 buckets."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project prefix for resource names."
  type        = string
  default     = "devops-lab"
}

variable "environment" {
  description = "Which environment to deploy."
  type        = string

  validation {
    condition     = contains(["devel", "stage"], var.environment)
    error_message = "environment must be 'devel' or 'stage'."
  }
}

variable "price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "log_retention_days" {
  type    = number
  default = 30
}
