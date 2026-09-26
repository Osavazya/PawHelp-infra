project     = "pawhelp"
environment = "prod"
aws_region  = "eu-central-1"

vpc_cidr            = "10.43.0.0/16"
public_subnet_cidrs = ["10.43.1.0/24", "10.43.2.0/24"]

instance_type                  = "t3.micro"
root_volume_size               = 30
control_plane_desired_capacity = 1
worker_desired_capacity        = 2

admin_cidr_blocks = []
enable_ssh        = false
key_name          = null

git_repo_url        = "https://github.com/Osavazya/PawHelp-infra.git"
git_target_revision = "main"


# Low-cost backup guardrail. Snapshot storage still has AWS cost.
enable_ebs_snapshots         = true
ebs_snapshot_interval_hours  = 24
ebs_snapshot_retention_count = 7
