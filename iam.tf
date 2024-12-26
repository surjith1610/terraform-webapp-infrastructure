# Creating combined IAM role for EC2 to access CloudWatch and S3
resource "aws_iam_role" "ec2_role" {
  name = "EC2CloudWatchS3Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attaching AWS managed policy for CloudWatch Agent
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Creating custom S3 policy to allow read, write, and delete on the bucket
resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3FullAccessPolicy"
  description = "Policy to allow EC2 full access to a specific S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.webapp_bucket.arn}/*"
      }
    ]
  })
  depends_on = [aws_s3_bucket.webapp_bucket]
}

# Attaching S3 policy to role
resource "aws_iam_role_policy_attachment" "s3_access_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Creating custom Secrets Manager policy for EC2 role to access secret
resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "SecretsManagerPolicy-EC2"
  description = "Policy to allow EC2 to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "${aws_secretsmanager_secret.db_password_secret.arn}"
      },
      {
        Effect = "Allow"
        Action = "kms:Decrypt"
      Resource = aws_kms_key.secrets_key.arn }
    ]
  })
}
# Attaching Secrets Manager policy to EC2 role
resource "aws_iam_role_policy_attachment" "secrets_manager_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}


# Creating IAM instance profile for the combined role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2InstanceProfileWithCloudWatchAndS3Accessnew"
  role = aws_iam_role.ec2_role.name
}

