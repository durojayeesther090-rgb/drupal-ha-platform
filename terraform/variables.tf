variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "project" {
  description = "Project name, used for naming and tagging"
  type        = string
  default     = "drupal-ha"
}

variable "environment" {
  description = "Environment name (staging or production)"
  type        = string
  default     = "staging"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to span (minimum 2)"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2
    error_message = "Use at least two Availability Zones."
  }
}

variable "instance_type" {
  description = "EC2 type for Drupal servers"
  type        = string
  default     = "t3.small"
}

variable "asg_min" {
  type    = number
  default = 2
}

variable "asg_max" {
  type    = number
  default = 4
}

variable "asg_desired" {
  type    = number
  default = 2
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_name" {
  type    = string
  default = "drupal"
}

variable "db_username" {
  type    = string
  default = "drupal_admin"
}

variable "ansible_repo_url" {
  description = "Git repo that servers pull the Ansible playbook from (ansible-pull)"
  type        = string
  default     = "https://github.com/durojayeesther090-rgb/drupal-ha-platform.git"
}

variable "ansible_repo_branch" {
  type    = string
  default = "main"
}

variable "allowed_cidr" {
  description = "CIDR allowed to reach the ALB over HTTP"
  type        = string
  default     = "0.0.0.0/0"
}
