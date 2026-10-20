variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  description = "Must match the project prefix used in infra/ (the role only touches buckets with this prefix)."
  type        = string
  default     = "devops-lab"
}

variable "state_bucket_name" {
  description = "Globally unique name for the Terraform state bucket, e.g. tfstate-luis-devops-lab-<random>. Must NOT start with the project prefix."
  type        = string
}

variable "github_owner" {
  description = "Your GitHub username or org."
  type        = string
}

variable "github_repo" {
  description = "Repository name, e.g. devops-lab."
  type        = string
}

variable "create_oidc_provider" {
  description = "Set to false if this AWS account already has the GitHub OIDC provider."
  type        = bool
  default     = true
}

variable "github_sub_prefix" {
  description = "OIDC subject prefix. Leave empty for repo:<owner>/<repo>; set it when the repo uses immutable subjects (see: gh api repos/<owner>/<repo>/actions/oidc/customization/sub)."
  type        = string
  default     = ""
}
