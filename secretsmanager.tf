# Generating a random password for the RDS instance
resource "random_password" "rds_password" {
  length  = 16
  special = false
  # override_special = "!#$%&*()-_=+<>?"
}

data "aws_caller_identity" "current" {}
# Creating KMS keys for EC2, RDS, S3, and Secrets Manager
resource "aws_kms_key" "ec2_key" {
  description             = "KMS key for EC2 encryption"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 30
  policy                  = <<EOF
{
    "Id": "key-for-ebs",
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow access for Key Administrators",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.id}:root"
            },
            "Action": [
                "kms:Create*",
                "kms:Describe*",
                "kms:Enable*",
                "kms:List*",
                "kms:Put*",
                "kms:Update*",
                "kms:Revoke*",
                "kms:Disable*",
                "kms:Get*",
                "kms:Delete*",
                "kms:TagResource",
                "kms:UntagResource",
                "kms:ScheduleKeyDeletion",
                "kms:CancelKeyDeletion"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow use of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow attachment of persistent resources",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
            },
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*",
            "Condition": {
                "Bool": {
                    "kms:GrantIsForAWSResource": "true"
                }
            }
        }
    ]
}
 
EOF
}

resource "aws_kms_key" "rds_key" {
  description             = "KMS key for RDS encryption"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/awscli"
          ]
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow RDS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 encryption"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 10
}

resource "aws_kms_key" "secrets_key" {
  description             = "KMS key for Secrets Manager"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

# Output the ARNs of the KMS keys
output "kms_key_arns" {
  value = {
    ec2     = aws_kms_key.ec2_key.arn
    rds     = aws_kms_key.rds_key.arn
    s3      = aws_kms_key.s3_key.arn
    secrets = aws_kms_key.secrets_key.arn
  }
}

# Database password secret
resource "aws_secretsmanager_secret" "db_password_secret" {
  name                    = "rds-db-password-1"
  recovery_window_in_days = 0
  kms_key_id              = aws_kms_key.secrets_key.id
}

resource "aws_secretsmanager_secret_version" "db_password_secret_version" {
  secret_id = aws_secretsmanager_secret.db_password_secret.id
  secret_string = jsonencode({
    "RDS_PASSWORD" = random_password.rds_password.result
  })
}

# Email credentials secret
resource "aws_secretsmanager_secret" "email_credentials_secret" {
  name                    = "email-credentials"
  recovery_window_in_days = 0
  kms_key_id              = aws_kms_key.secrets_key.id
}

resource "aws_secretsmanager_secret_version" "email_credentials_secret_version" {
  secret_id = aws_secretsmanager_secret.email_credentials_secret.id
  secret_string = jsonencode({
    "SENDGRID_API_KEY" = var.sendgrid_api_key
    "DOMAIN_NAME"      = var.domain_name
  })
}
