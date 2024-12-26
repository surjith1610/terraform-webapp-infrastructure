resource "aws_security_group" "webapp_sg" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    from_port = 8000
    to_port   = 8000
    protocol  = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.load_balancer_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "web application security group"
  }

  depends_on = [aws_vpc.vpc]
}

# Create EC2 Instance
# resource "aws_instance" "web_app_instance" {
#   ami                         = var.ami_id
#   instance_type               = var.ec2_instance_type
#   subnet_id                   = aws_subnet.public_subnets[0].id
#   vpc_security_group_ids      = [aws_security_group.webapp_sg.id]
#   associate_public_ip_address = true
#   iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

#   root_block_device {
#     volume_size           = var.ec2_intance_volume_size
#     volume_type           = var.ec2_volumetype
#     delete_on_termination = true
#   }

#   disable_api_termination = false

#   user_data = <<-EOF
#     #!/bin/bash
#     LOG_DIR="/home/csye6225/webapp/logs"
#     LOG_FILE="$LOG_DIR/user-data-log.txt"
#     WEBAPP_LOG="$LOG_DIR/webapp.log"

#     # Ensure the logs directory exists
#     if [ ! -d "$LOG_DIR" ]; then
#       mkdir -p "$LOG_DIR" || echo "Error creating logs directory" >> "$LOG_FILE"
#     fi

#     if [ ! -f "$WEBAPP_LOG" ]; then
#       touch "$WEBAPP_LOG" || echo "Error creating webapp.log file" >> "$LOG_FILE"
#     fi

#     LOG_FILE="/home/csye6225/webapp/logs/user-data-log.txt"

#     echo "Starting user data script..." >> "$LOG_FILE"

#     echo "Setting environment variables..." >> "$LOG_FILE"
#     {
#     echo "DB_HOST='${aws_db_instance.csye6225_appdb.address}'" >> /etc/environment
#     echo "DB_USER='${var.db_username}'" >> /etc/environment
#     echo "DB_PASSWORD='${var.db_password}'" >> /etc/environment
#     echo "DB_NAME='${var.db_name}'" >> /etc/environment
#     echo "DB_PORT='${var.db_port}'" >> /etc/environment
#     echo "S3_BUCKET_NAME='${aws_s3_bucket.webapp_bucket.bucket}'" >> /etc/environment
#     } || echo "Error setting environment variables" >> "$LOG_FILE"

#     echo "Activating environment..." >> "$LOG_FILE"

#     source /etc/environment || echo "Error sourcing environment variables" >> "$LOG_FILE"

#     echo "Running migrations..." >> "$LOG_FILE"
#     # running database migrations
#     sudo -u csye6225 bash -c 'source /home/csye6225/webapp/venv/bin/activate && python3 /home/csye6225/webapp/manage.py makemigrations && python3 /home/csye6225/webapp/manage.py migrate' >> "$LOG_FILE" 2>&1 || echo "Error running migrations" >> "$LOG_FILE"

#     echo "Checking if $WEBAPP_LOG is writable..." >> "$LOG_FILE"
#     if [ -w "$WEBAPP_LOG" ]; then
#       echo "$WEBAPP_LOG is writable." >> "$LOG_FILE"
#     else
#       echo "$WEBAPP_LOG is not writable. Making it writable." >> "$LOG_FILE"
#       chmod +w "$WEBAPP_LOG" || echo "Error making $WEBAPP_LOG writable" >> "$LOG_FILE"
#       fi

#     echo "Reloading and restarting services..." >> "$LOG_FILE"
#     # Reload and restart services after loading environment variables
#     systemctl daemon-reload || echo "Error reloading systemd" >> "$LOG_FILE"
#     systemctl enable webapp.service || echo "Error enabling webapp service" >> "$LOG_FILE"
#     systemctl restart webapp.service || echo "Error restarting webapp service" >> "$LOG_FILE"

#     echo "Configuring CloudWatch Agent..." >> "$LOG_FILE"
#     # Configure CloudWatch Agent
#     sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc || echo "Error creating CloudWatch directory" >> "$LOG_FILE"
#     sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null << 'EOT'
#       {
#         "agent": {
#           "metrics_collection_interval": 60,
#           "run_as_user": "root"
#         },
#         "logs": {
#           "logs_collected": {
#             "files": {
#               "collect_list": [
#                 {
#                   "file_path": "/home/csye6225/webapp/logs/webapp.log",
#                   "log_group_name": "/webapp/application",
#                   "log_stream_name": "{instance_id}",
#                   "timestamp_format": "%Y-%m-%d %H:%M:%S"
#                 }
#               ]
#             }
#           }
#         },
#       "metrics": {
#           "namespace": "CustomAppMetrics",
#           "metrics_collected": {
#             "statsd": {
#               "service_address": ":8125",
#               "metrics_collection_interval": 60
#             },
#             "cpu": {
#               "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
#               "metrics_collection_interval": 60
#             },
#             "disk": {
#               "measurement": ["used_percent"],
#               "metrics_collection_interval": 60,
#               "resources": ["*"]
#             },
#             "mem": {
#               "measurement": ["mem_used_percent"],
#               "metrics_collection_interval": 60
#             }
#           }
#         }
#       }
#     EOT

#     echo "Starting CloudWatch agent..." >> "$LOG_FILE"
#     # Start CloudWatch agent with new configuration
#     sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json || echo "Error starting CloudWatch agent" >> "$LOG_FILE"
#     sudo systemctl restart amazon-cloudwatch-agent || echo "Error restarting CloudWatch agent" >> "$LOG_FILE"

#     echo "User data script completed." >> "$LOG_FILE"
# EOF

#   tags = {
#     Name = "web_app_instance"
#   }

#   depends_on = [aws_internet_gateway.igw, aws_subnet.public_subnets, aws_security_group.webapp_sg, aws_db_instance.csye6225_appdb, aws_s3_bucket.webapp_bucket]
# }
