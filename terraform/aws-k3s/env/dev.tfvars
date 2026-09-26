project     = "pawhelp"
environment = "dev"
aws_region  = "eu-central-1"

vpc_cidr            = "10.42.0.0/16"
public_subnet_cidrs = ["10.42.1.0/24", "10.42.2.0/24"]

instance_type                  = "t3.micro"
root_volume_size               = 30
control_plane_desired_capacity = 1
worker_desired_capacity        = 2

admin_cidr_blocks = []
enable_ssh        = false
key_name          = null

git_repo_url        = "https://github.com/Osavazya/PawHelp-infra.git"
git_target_revision = "master"


# Low-cost backup guardrail. Snapshot storage still has AWS cost.
enable_ebs_snapshots           = true
ebs_snapshot_interval_hours    = 24
ebs_snapshot_retention_count   = 3
backup_bucket_force_destroy    = true
postgres_backup_retention_days = 7
ecr_force_delete               = true


enable_wireguard              = true
wireguard_port                = 51820
wireguard_address             = "10.44.0.1/24"
wireguard_allowed_cidr_blocks = ["0.0.0.0/0"]
internal_access_cidr_blocks   = ["10.44.0.0/24"]
wireguard_peers               = []
