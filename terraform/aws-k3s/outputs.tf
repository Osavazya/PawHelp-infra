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

output "worker_asg" {
  value = aws_autoscaling_group.worker.name
}

output "ssm_session_hint" {
  value = "aws ssm start-session --target <instance-id> --region ${var.aws_region}"
}

