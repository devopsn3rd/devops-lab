terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.80, < 7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Partial backend config: bucket, key and region are passed at `terraform init`
  # with -backend-config. Each environment gets its own state key, so devel and
  # stage are fully isolated (a broken devel apply can't touch stage).
  backend "s3" {
    encrypt      = true
    use_lockfile = true # native S3 locking, no DynamoDB table needed (TF >= 1.10)
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "site" {
  source = "./modules/static-site"

  project            = var.project
  environment        = var.environment
  price_class        = var.price_class
  log_retention_days = var.log_retention_days
}
