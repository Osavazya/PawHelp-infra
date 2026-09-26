variable "project" {
  type        = string
  description = "Project name."
  default     = "pawhelp"
}

variable "environment" {
  type        = string
  description = "Environment name."
}

variable "aws_region" {
  type        = string
  description = "AWS region."
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs."
}

variable "instance_type" {
  type        = string
  description = "EC2 type for Kubernetes nodes."
  default     = "t3.micro"
}

variable "root_volume_size" {
  type        = number
  description = "Root EBS volume size in GiB."
  default     = 30
}

variable "control_plane_desired_capacity" {
  type    = number
  default = 1
}

variable "worker_desired_capacity" {
  type    = number
  default = 2
}

variable "admin_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to reach SSH and Kubernetes API."
  default     = []
}

variable "enable_ssh" {
  type        = bool
  description = "Open SSH from admin_cidr_blocks."
  default     = false
}

variable "key_name" {
  type        = string
  description = "Optional EC2 key pair."
  default     = null
}

variable "git_repo_url" {
  type        = string
  description = "Git repository URL used by Argo CD app-of-apps."
  default     = ""
}

variable "git_target_revision" {
  type        = string
  description = "Git revision used by Argo CD."
  default     = "main"
}

variable "artifact_bucket_force_destroy" {
  type        = bool
  default     = false
}

