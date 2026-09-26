data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "postgres_backups" {
  bucket        = "${local.name}-postgres-backups-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  force_destroy = var.backup_bucket_force_destroy

  tags = {
    Name        = "${local.name}-postgres-backups"
    Project     = var.project
    Environment = var.environment
    Purpose     = "postgres-backups"
  }
}

resource "aws_s3_bucket_public_access_block" "postgres_backups" {
  bucket                  = aws_s3_bucket.postgres_backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "postgres_backups" {
  bucket = aws_s3_bucket.postgres_backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "postgres_backups" {
  bucket = aws_s3_bucket.postgres_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "postgres_backups" {
  bucket = aws_s3_bucket.postgres_backups.id

  rule {
    id     = "expire-postgres-dumps"
    status = "Enabled"

    filter {
      prefix = "postgres/"
    }

    expiration {
      days = var.postgres_backup_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.postgres_backup_retention_days
    }
  }
}

resource "aws_ssm_parameter" "postgres_backup_bucket" {
  name  = "/${var.project}/${var.environment}/postgres-backup/S3_BUCKET"
  type  = "String"
  value = aws_s3_bucket.postgres_backups.bucket
}

resource "aws_ssm_parameter" "postgres_backup_prefix" {
  name  = "/${var.project}/${var.environment}/postgres-backup/S3_PREFIX"
  type  = "String"
  value = "postgres/${var.environment}"
}

resource "aws_ssm_parameter" "postgres_backup_region" {
  name  = "/${var.project}/${var.environment}/postgres-backup/AWS_REGION"
  type  = "String"
  value = var.aws_region
}

resource "aws_iam_role_policy" "runtime_secrets_and_backups" {
  name = "${local.name}-runtime-secrets-and-backups"
  role = aws_iam_role.node.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project}/${var.environment}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.postgres_backups.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.postgres_backups.arn}/*"
      }
    ]
  })
}
