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

output "grafana_url" {
  description = "Open this to see the dashboards (user: admin)"
  value       = try("http://${aws_instance.monitoring[0].public_ip}:3000", null)
}

output "prometheus_url" {
  description = "Prometheus: Status > Targets shows every server being scraped; Alerts shows the alert rules"
  value       = try("http://${aws_instance.monitoring[0].public_ip}:9090", null)
}

output "grafana_password_command" {
  description = "Run this to print the Grafana admin password"
  value       = "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.db.arn} --region ${var.region} --query SecretString --output text | python3 -c \"import sys,json; print(json.load(sys.stdin)['grafana_password'])\""
}

output "github_actions_role_arn" {
  description = "Put this in the GitHub variable AWS_DEPLOY_ROLE_ARN"
  value       = try(aws_iam_role.github_actions[0].arn, null)
}
