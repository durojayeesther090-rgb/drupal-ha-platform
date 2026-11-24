# Production environment. Build it in its own Terraform workspace so it has separate state:
#   terraform workspace new production
#   terraform apply -var-file=production.tfvars
region      = "eu-west-1"
project     = "drupal-ha"
environment = "production"

instance_type = "t3.small"
asg_min       = 2
asg_max       = 6
asg_desired   = 2

# Use 7 days of backups on a paid AWS plan (free plan allows 1)
db_backup_retention_days = 1

ansible_repo_url = "https://github.com/durojayeesther090-rgb/drupal-ha-platform.git"

# The GitHub deploy role is created once (by staging) and shared
enable_github_actions_role = false
