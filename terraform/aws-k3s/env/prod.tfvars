project     = "pawhelp"
environment = "prod"
aws_region  = "eu-central-1"

vpc_cidr            = "10.43.0.0/16"
public_subnet_cidrs = ["10.43.1.0/24", "10.43.2.0/24"]

instance_type                    = "t3.micro"
root_volume_size                 = 30
control_plane_desired_capacity   = 1
frontend_worker_desired_capacity = 1
backend_worker_desired_capacity  = 1
infra_worker_desired_capacity    = 0

admin_cidr_blocks = []
enable_ssh        = false
key_name          = null

git_repo_url        = "https://github.com/Osavazya/PawHelp-infra.git"
git_target_revision = "prod"
enable_argocd       = false


# Low-cost backup guardrail. Snapshot storage still has AWS cost.
enable_ebs_snapshots           = true
ebs_snapshot_interval_hours    = 24
ebs_snapshot_retention_count   = 7
backup_bucket_force_destroy    = false
postgres_backup_retention_days = 30
ecr_force_delete               = false


enable_wireguard              = true
wireguard_port                = 51820
wireguard_address             = "10.45.0.1/24"
wireguard_allowed_cidr_blocks = ["0.0.0.0/0"]
internal_access_cidr_blocks   = ["10.45.0.0/24"]
wireguard_peers               = []
