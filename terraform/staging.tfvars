region      = "eu-west-1"
project     = "drupal-ha"
environment = "staging"

instance_type = "t3.small"
asg_min       = 2
asg_max       = 4
asg_desired   = 2

# AWS free-plan accounts only allow 1 day of RDS backups. Use 7 on a paid plan.
db_backup_retention_days = 1

ansible_repo_url = "https://github.com/durojayeesther090-rgb/drupal-ha-platform.git"

# Lets the GitHub Actions pipeline deploy to this environment
enable_github_actions_role = true
github_oidc_provider_exists = true
