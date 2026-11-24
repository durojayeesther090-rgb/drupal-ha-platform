# Monitoring and logging.
#   - One small server runs Prometheus + Grafana (configured by Ansible, see ansible/monitoring.yml).
#   - Prometheus finds the Drupal servers by their EC2 tag, so new auto-scaled servers appear on their own.
#   - CloudWatch Logs keeps Apache and system logs from every Drupal server in one place.
#   - CloudWatch alarms watch the load balancer, database and auto scaling group and send email through SNS.
# Switch off with: enable_monitoring = false

locals {
  log_prefix = "/${var.project}/${var.environment}"
}

# ------------------------------------------------------------------ Central logs
resource "aws_cloudwatch_log_group" "apache_access" {
  name              = "${local.log_prefix}/apache-access"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "apache_error" {
  name              = "${local.log_prefix}/apache-error"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "syslog" {
  name              = "${local.log_prefix}/syslog"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "bootstrap" {
  name              = "${local.log_prefix}/bootstrap"
  retention_in_days = var.log_retention_days
}

# ------------------------------------------------------------------ Alerts by email
resource "aws_sns_topic" "alerts" {
  name = "${local.name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.name}-alb-5xx-errors"
  alarm_description   = "The load balancer is returning server errors"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { LoadBalancer = aws_lb.app.arn_suffix }
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${local.name}-unhealthy-servers"
  alarm_description   = "At least one Drupal server is failing its health check"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${local.name}-db-cpu-high"
  alarm_description   = "Database CPU above 80% for 10 minutes"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { DBInstanceIdentifier = aws_db_instance.main.identifier }
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${local.name}-db-connections-high"
  alarm_description   = "Database connections are close to the limit of a small instance"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 50
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { DBInstanceIdentifier = aws_db_instance.main.identifier }
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu" {
  alarm_name          = "${local.name}-servers-cpu-high"
  alarm_description   = "Average CPU of the Drupal servers above 80% for 10 minutes"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.app.name }
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# ------------------------------------------------------------------ Prometheus + Grafana server
resource "aws_security_group" "monitoring" {
  count       = var.enable_monitoring ? 1 : 0
  name        = "${local.name}-monitoring-sg"
  description = "Grafana and Prometheus web interfaces"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.monitoring_allowed_cidr]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.monitoring_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "monitoring" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${local.name}-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "monitoring_ssm" {
  count      = var.enable_monitoring ? 1 : 0
  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Grafana reads load balancer and database metrics from CloudWatch
resource "aws_iam_role_policy_attachment" "monitoring_cloudwatch" {
  count      = var.enable_monitoring ? 1 : 0
  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_role_policy" "monitoring_access" {
  count = var.enable_monitoring ? 1 : 0
  name  = "discover-servers-and-read-secret"
  role  = aws_iam_role.monitoring[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:DescribeInstances"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.db.arn
      },
    ]
  })
}

resource "aws_iam_instance_profile" "monitoring" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${local.name}-monitoring-profile"
  role  = aws_iam_role.monitoring[0].name
}

resource "aws_instance" "monitoring" {
  count                       = var.enable_monitoring ? 1 : 0
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.monitoring_instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.monitoring[0].id]
  iam_instance_profile        = aws_iam_instance_profile.monitoring[0].name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data_monitoring.sh.tpl", {
    region      = var.region
    secret_arn  = aws_secretsmanager_secret.db.arn
    repo_url    = var.ansible_repo_url
    repo_branch = var.ansible_repo_branch
  })
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${local.name}-monitoring"
    Role = "monitoring"
  }

  # The database must exist (Prometheus reads its metrics) and the secret must hold the passwords
  depends_on = [aws_db_instance.main, aws_secretsmanager_secret_version.db]
}
