output "alb_dns_name" {
  description = "Open this URL to reach Drupal"
  value       = aws_lb.app.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.main.address
}

output "efs_id" {
  value = aws_efs_file_system.drupal_files.id
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "github_actions_role_arn" {
  description = "Put this in the GitHub variable AWS_DEPLOY_ROLE_ARN"
  value       = try(aws_iam_role.github_actions[0].arn, null)
}
