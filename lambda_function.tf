# resource "aws_security_group" "lambda_sg" {
#   name        = "lambda-security-group"
#   description = "Allow Lambda to access RDS"
#   vpc_id      = aws_vpc.vpc.id

#   # Allow all outbound traffic (typical for Lambda functions)
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "lambda-security-group"
#   }
# }

# resource "aws_security_group_rule" "lambda_to_db" {
#   type                     = "ingress"
#   from_port                = 5432
#   to_port                  = 5432
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.db_sg.id
#   source_security_group_id = aws_security_group.lambda_sg.id
# }

resource "aws_lambda_function" "user_verification_lambda" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = var.lambda_function_handler
  runtime       = var.lambda_function_runtime

  timeout     = 60
  memory_size = 128

  # Reference the Lambda code from the local file
  filename = "${path.module}/${var.lambda_file_path}"

  environment {
    variables = {
      # SENDGRID_API_KEY = var.sendgrid_api_key
      # DOMAIN_URL       = var.domain_name
      #   RDS_DB_NAME      = var.db_name
      #   RDS_USER         = var.db_username
      #   RDS_PASSWORD     = var.db_password
      #   RDS_HOST         = aws_db_instance.csye6225_appdb.address
    }
  }

  #   vpc_config {
  #     subnet_ids         = aws_subnet.public_subnets[*].id
  #     security_group_ids = [aws_security_group.lambda_sg.id]
  #   }
}

resource "aws_lambda_permission" "allow_sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_verification_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.user_verification_topic.arn
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "sns_publish_policy" {
  name        = "sns-publish-policy"
  description = "Policy to allow EC2 instance to publish to SNS topic"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "sns:Publish",
        "Resource" : aws_sns_topic.user_verification_topic.arn
      }
    ]
  })
}

# Attach SNS publish policy to the EC2 role
resource "aws_iam_role_policy_attachment" "attach_sns_publish_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.sns_publish_policy.arn
}

resource "aws_iam_policy" "cloudwatch_logs_policy" {
  name        = "cloudwatch-logs-policy"
  description = "Policy to allow Lambda to create and write logs to CloudWatch"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_logs_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs_policy.arn
}

resource "aws_iam_policy" "lambda_secrets_manager_policy" {
  name        = "SecretsManagerPolicy-Lambda"
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
        Resource = "arn:aws:secretsmanager:us-east-1:*:secret:*"
      },
      {
        Effect = "Allow"
        Action = "kms:Decrypt"
      Resource = aws_kms_key.secrets_key.arn }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_manager_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_secrets_manager_policy.arn
}
