region      = "eu-west-1"
project     = "drupal-ha"
environment = "staging"

instance_type = "t3.small"
asg_min       = 2
asg_max       = 4
asg_desired   = 2

ansible_repo_url = "https://github.com/durojayeesther090-rgb/drupal-ha-platform.git"
