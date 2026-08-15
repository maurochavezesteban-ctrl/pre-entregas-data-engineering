# ============================================================
# 1. DATA PROCESSING ROLE (para futuros Lambda / Flink / etc.)
# ============================================================

resource "aws_iam_role" "data_processing" {
  name = "data-processing-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = var.assume_role_services
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "data-processing-role-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "data_processing_s3" {
  name        = "data-processing-s3-policy-${var.environment}"
  description = "Permite ListBucket, GetObject y PutObject sobre el prefijo del Data Lake"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucketWithPrefix"
        Effect = "Allow"
        Action = "s3:ListBucket"
        Resource = var.data_lake_bucket_arn
        Condition = {
          StringLike = {
            "s3:prefix" = ["${var.data_lake_prefix}*"]
          }
        }
      },
      {
        Sid    = "GetPutObjectsInPrefix"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${var.data_lake_bucket_arn}/${var.data_lake_prefix}*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "data_processing_attach" {
  role       = aws_iam_role.data_processing.name
  policy_arn = aws_iam_policy.data_processing_s3.arn
}


# ============================================================
# 2. CONTROL PLANE READ-ONLY ROLE (auditoría, mínimo privilegio)
# ============================================================

resource "aws_iam_role" "control_plane_readonly" {
  name = "control-plane-readonly-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.control_plane_trusted_arn
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "control-plane-readonly-role-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "control_plane_readonly_policy" {
  name        = "control-plane-readonly-policy-${var.environment}"
  description = "Solo lectura sobre los recursos que crea este proyecto (VPC/EC2 e IAM)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadOnlyNetwork"
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables",
          "ec2:DescribeVpcEndpoints"
        ]
        Resource = "*"
      },
      {
        Sid    = "ReadOnlyIdentity"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "control_plane_readonly_attach" {
  role       = aws_iam_role.control_plane_readonly.name
  policy_arn = aws_iam_policy.control_plane_readonly_policy.arn
}