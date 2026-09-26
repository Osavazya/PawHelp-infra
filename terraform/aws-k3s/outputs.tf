output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = values(aws_subnet.public)[*].id
}

output "artifact_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}

output "control_plane_asg" {
  value = aws_autoscaling_group.control_plane.name
}

output "worker_asgs" {
  value = { for pool, asg in aws_autoscaling_group.worker : pool => asg.name }
}

output "ssm_session_hint" {
  value = "aws ssm start-session --target <instance-id> --region ${var.aws_region}"
}

output "control_plane_eip" {
  value = aws_eip.control_plane.public_ip
}

output "postgres_backup_bucket" {
  value = aws_s3_bucket.postgres_backups.bucket
}

output "backend_ecr_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "frontend_ecr_repository_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "wireguard_endpoint" {
  value = var.enable_wireguard ? "${aws_eip.control_plane.public_ip}:${var.wireguard_port}" : null
}

output "wireguard_server_address" {
  value = var.enable_wireguard ? var.wireguard_address : null
}
