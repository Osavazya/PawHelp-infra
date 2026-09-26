variable "project" {
  type        = string
  description = "Project name used in AWS resource names."
}

variable "aws_region" {
  type        = string
  description = "AWS region."
}

variable "force_destroy" {
  type        = bool
  description = "Allow deletion of non-empty state bucket."
  default     = false
}

