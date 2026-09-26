data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  name              = "${var.project}-${var.environment}"
  azs               = slice(data.aws_availability_zones.available.names, 0, length(var.public_subnet_cidrs))
  ssm_prefix        = "/${var.project}/${var.environment}/k3s"
  control_plane_tag = "${local.name}-control-plane"
  worker_tag        = "${local.name}-worker"
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = "${local.name}-artifacts-${random_id.suffix.hex}"
  force_destroy = var.artifact_bucket_force_destroy
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_eip" "control_plane" {
  domain = "vpc"

  tags = {
    Name = "${local.name}-control-plane"
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = local.name
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = local.name
  }
}

resource "aws_subnet" "public" {
  for_each = {
    for index, cidr in var.public_subnet_cidrs : index => cidr
  }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = local.azs[tonumber(each.key)]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name}-public-${each.key}"
    Tier = "public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${local.name}-public"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "k3s" {
  name        = "${local.name}-k3s"
  description = "PawHelp Kubernetes nodes"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.name}-k3s"
  }
}

resource "aws_security_group_rule" "http" {
  type              = "ingress"
  security_group_id = aws_security_group.k3s.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP ingress"
}

resource "aws_security_group_rule" "https" {
  type              = "ingress"
  security_group_id = aws_security_group.k3s.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS ingress"
}

resource "aws_security_group_rule" "kubernetes_api_admin" {
  count             = length(var.admin_cidr_blocks) > 0 ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.k3s.id
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = var.admin_cidr_blocks
  description       = "Kubernetes API from admin networks"
}

resource "aws_security_group_rule" "ssh_admin" {
  count             = var.enable_ssh && length(var.admin_cidr_blocks) > 0 ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.k3s.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.admin_cidr_blocks
  description       = "SSH from admin networks"
}

resource "aws_security_group_rule" "node_tcp" {
  type                     = "ingress"
  security_group_id        = aws_security_group.k3s.id
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.k3s.id
  description              = "Node-to-node TCP"
}

resource "aws_security_group_rule" "node_udp" {
  type                     = "ingress"
  security_group_id        = aws_security_group.k3s.id
  from_port                = 0
  to_port                  = 65535
  protocol                 = "udp"
  source_security_group_id = aws_security_group.k3s.id
  description              = "Node-to-node UDP"
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  security_group_id = aws_security_group.k3s.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All outbound"
}

resource "aws_iam_role" "node" {
  name = "${local.name}-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "cluster_bootstrap" {
  name = "${local.name}-cluster-bootstrap"
  role = aws_iam_role.node.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:PutParameter",
          "ssm:DeleteParameter"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter${local.ssm_prefix}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AssociateAddress",
          "ec2:DescribeAddresses",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role" "dlm" {
  count = var.enable_ebs_snapshots ? 1 : 0
  name  = "${local.name}-dlm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "dlm.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dlm" {
  count      = var.enable_ebs_snapshots ? 1 : 0
  role       = aws_iam_role.dlm[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}

resource "aws_dlm_lifecycle_policy" "node_volumes" {
  count              = var.enable_ebs_snapshots ? 1 : 0
  description        = "${local.name} node EBS snapshots"
  execution_role_arn = aws_iam_role.dlm[0].arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    target_tags = {
      Project     = var.project
      Environment = var.environment
      Backup      = "true"
    }

    schedule {
      name = "daily-node-volume-snapshots"

      create_rule {
        interval      = var.ebs_snapshot_interval_hours
        interval_unit = "HOURS"
      }

      retain_rule {
        count = var.ebs_snapshot_retention_count
      }

      tags_to_add = {
        Project     = var.project
        Environment = var.environment
        CreatedBy   = "dlm"
      }

      copy_tags = true
    }
  }
}

resource "aws_iam_instance_profile" "node" {
  name = "${local.name}-node"
  role = aws_iam_role.node.name
}

resource "aws_launch_template" "control_plane" {
  name_prefix   = "${local.name}-control-plane-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.node.name
  }

  vpc_security_group_ids = [aws_security_group.k3s.id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      encrypted             = true
      delete_on_termination = true
      volume_type           = "gp3"
      volume_size           = var.root_volume_size
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  user_data = base64encode(templatefile("${path.module}/templates/control-plane.sh.tftpl", {
    aws_region                       = var.aws_region
    project                          = var.project
    environment                      = var.environment
    ssm_prefix                       = local.ssm_prefix
    control_plane_eip_allocation_id  = aws_eip.control_plane.id
    control_plane_eip_public_ip      = aws_eip.control_plane.public_ip
    git_repo_url                     = var.git_repo_url
    git_target_revision              = var.git_target_revision
    enable_wireguard                 = var.enable_wireguard
    wireguard_port                   = var.wireguard_port
    wireguard_address                = var.wireguard_address
    wireguard_peers_json             = jsonencode(var.wireguard_peers)
    internal_access_cidr_blocks_yaml = join("\n", [for cidr in var.internal_access_cidr_blocks : "            - ${cidr}"])
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = local.control_plane_tag
      Role = "control-plane"
    }
  }
  tag_specifications {
    resource_type = "volume"

    tags = {
      Name        = local.control_plane_tag
      Role        = "control-plane"
      Project     = var.project
      Environment = var.environment
      Backup      = "true"
    }
  }
}

resource "aws_launch_template" "worker" {
  name_prefix   = "${local.name}-worker-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.node.name
  }

  vpc_security_group_ids = [aws_security_group.k3s.id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      encrypted             = true
      delete_on_termination = true
      volume_type           = "gp3"
      volume_size           = var.root_volume_size
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  user_data = base64encode(templatefile("${path.module}/templates/worker.sh.tftpl", {
    aws_region  = var.aws_region
    ssm_prefix  = local.ssm_prefix
    environment = var.environment
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = local.worker_tag
      Role = "worker"
    }
  }
  tag_specifications {
    resource_type = "volume"

    tags = {
      Name        = local.worker_tag
      Role        = "worker"
      Project     = var.project
      Environment = var.environment
      Backup      = "true"
    }
  }
}

resource "aws_autoscaling_group" "control_plane" {
  name                = "${local.name}-control-plane"
  min_size            = 1
  max_size            = 1
  desired_capacity    = var.control_plane_desired_capacity
  vpc_zone_identifier = values(aws_subnet.public)[*].id
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.control_plane.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = local.control_plane_tag
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "control-plane"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "worker" {
  name                = "${local.name}-worker"
  min_size            = 2
  max_size            = 2
  desired_capacity    = var.worker_desired_capacity
  vpc_zone_identifier = values(aws_subnet.public)[*].id
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = local.worker_tag
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "worker"
    propagate_at_launch = true
  }
}



