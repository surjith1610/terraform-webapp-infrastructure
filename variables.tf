variable "vpc_cidr" {
  type        = string
  description = "value of cidr block"
}

variable "vpc_name" {
  type        = string
  description = "value of vpc name"

}

variable "internet_gateway_name" {
  type        = string
  description = "value of internet gateway name"

}

variable "aws_region" {
  type        = string
  description = "value of aws region"

}

variable "ami_id" {
  type        = string
  description = "value of ami id"
}


variable "db_password" {
  description = "Password for the PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432

}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ec2_volumetype" {
  description = "EC2 volume type"
  type        = string
}

variable "ec2_instance_volume_size" {
  description = "EC2 instance volume size"
  type        = number

}

variable "rds_instance_type" {
  description = "RDS instance type"
  type        = string
}

variable "rds_engine" {
  description = "RDS engine"
  type        = string
}

variable "rds_identifier" {
  description = "RDS identifier"
  type        = string
}

variable "rds_storage_size" {
  description = "RDS storage size"
  type        = number
}

# variable "environment" {
#   description = "Environment name"
#   type        = string
# }

variable "domain_name" {
  description = "Domain name"
  type        = string
}

variable "ec2_launch_template_ssh_key" {
  description = "SSH key name for EC2 launch template"
  type        = string
}

variable "upscale_threshold" {
  description = "Upscale threshold"
  type        = number
}

variable "downscale_threshold" {
  description = "Downscale threshold"
  type        = number
}

variable "sns_topic_name" {
  description = "Name of the SNS topic"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "lambda_function_handler" {
  description = "Lambda function handler"
  type        = string

}

variable "lambda_function_runtime" {
  description = "Lambda function runtime"
  type        = string
}

variable "lambda_file_path" {
  description = "Path to the Lambda function code"
  type        = string
}

variable "sendgrid_api_key" {
  description = "SendGrid API key"
  type        = string
  sensitive   = true
}
