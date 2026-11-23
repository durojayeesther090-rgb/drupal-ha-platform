# Shared storage so every Drupal server sees the same sites/default/files
resource "aws_efs_file_system" "drupal_files" {
  encrypted = true
  tags      = { Name = "${local.name}-files" }
}

resource "aws_efs_mount_target" "app" {
  count           = var.az_count
  file_system_id  = aws_efs_file_system.drupal_files.id
  subnet_id       = aws_subnet.app[count.index].id
  security_groups = [aws_security_group.efs.id]
}
