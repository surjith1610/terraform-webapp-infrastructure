locals {
  RDS_PASSWORD = jsondecode(aws_secretsmanager_secret_version.db_password_secret_version.secret_string).RDS_PASSWORD
  user_data    = <<-EOF
    #!/bin/bash
    LOG_DIR="/home/csye6225/webapp/logs"
    LOG_FILE="$LOG_DIR/user-data-log.txt"
    WEBAPP_LOG="$LOG_DIR/webapp.log"
 
    # Ensure the logs directory exists
    if [ ! -d "$LOG_DIR" ]; then
      mkdir -p "$LOG_DIR" || echo "Error creating logs directory" >> "$LOG_FILE"
    fi

    if [ ! -f "$WEBAPP_LOG" ]; then
      touch "$WEBAPP_LOG" || echo "Error creating webapp.log file" >> "$LOG_FILE"
    fi

    LOG_FILE="/home/csye6225/webapp/logs/user-data-log.txt"

    echo "Starting user data script..." >> "$LOG_FILE"

    echo "Data base password printtttttt______'${local.RDS_PASSWORD}'" >> "$LOG_FILE"
      
    echo "Setting environment variables..." >> "$LOG_FILE"
    {
    echo "DB_HOST='${aws_db_instance.csye6225_appdb.address}'" >> /etc/environment
    echo "DB_USER='${var.db_username}'" >> /etc/environment
    echo "DB_PASSWORD='${local.RDS_PASSWORD}'" >> /etc/environment
    echo "DB_NAME='${var.db_name}'" >> /etc/environment
    echo "DB_PORT='${var.db_port}'" >> /etc/environment
    echo "S3_BUCKET_NAME='${aws_s3_bucket.webapp_bucket.bucket}'" >> /etc/environment
    echo "SNS_TOPIC_ARN='${aws_sns_topic.user_verification_topic.arn}'" >> /etc/environment
    } || echo "Error setting environment variables" >> "$LOG_FILE"

    echo "Activating environment..." >> "$LOG_FILE"

    source /etc/environment || echo "Error sourcing environment variables" >> "$LOG_FILE"

    source /etc/environment

    echo "Running migrations..." >> "$LOG_FILE"
    # running database migrations
    sudo -u csye6225 bash -c 'source /home/csye6225/webapp/venv/bin/activate && python3 /home/csye6225/webapp/manage.py makemigrations && python3 /home/csye6225/webapp/manage.py migrate' >> "$LOG_FILE" 2>&1 || echo "Error running migrations" >> "$LOG_FILE"

    echo "Checking if $WEBAPP_LOG is writable..." >> "$LOG_FILE"
    if [ -w "$WEBAPP_LOG" ]; then
      echo "$WEBAPP_LOG is writable." >> "$LOG_FILE"
    else
      echo "$WEBAPP_LOG is not writable. Making it writable." >> "$LOG_FILE"
      chmod +w "$WEBAPP_LOG" || echo "Error making $WEBAPP_LOG writable" >> "$LOG_FILE"
      fi

    echo "Reloading and restarting services..." >> "$LOG_FILE"
    # Reload and restart services after loading environment variables
    systemctl daemon-reload || echo "Error reloading systemd" >> "$LOG_FILE"
    systemctl enable webapp.service || echo "Error enabling webapp service" >> "$LOG_FILE"
    systemctl restart webapp.service || echo "Error restarting webapp service" >> "$LOG_FILE"

    echo "Configuring CloudWatch Agent..." >> "$LOG_FILE"
    # Configure CloudWatch Agent
    sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc || echo "Error creating CloudWatch directory" >> "$LOG_FILE"
    sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null << 'EOT'
      {
        "agent": {
          "metrics_collection_interval": 60,
          "run_as_user": "root"
        },
        "logs": {
          "logs_collected": {
            "files": {
              "collect_list": [
                {
                  "file_path": "/home/csye6225/webapp/logs/webapp.log",
                  "log_group_name": "/webapp/application",
                  "log_stream_name": "{instance_id}",
                  "timestamp_format": "%Y-%m-%d %H:%M:%S"
                }
              ]
            }
          }
        },
      "metrics": {
          "namespace": "CustomAppMetrics",
          "metrics_collected": {
            "statsd": {
              "service_address": ":8125",
              "metrics_collection_interval": 60
            },
            "cpu": {
              "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
              "metrics_collection_interval": 60
            },
            "disk": {
              "measurement": ["used_percent"],
              "metrics_collection_interval": 60,
              "resources": ["*"]
            },
            "mem": {
              "measurement": ["mem_used_percent"],
              "metrics_collection_interval": 60
            }
          }
        }
      }
    EOT
 
    echo "Starting CloudWatch agent..." >> "$LOG_FILE"
    # Start CloudWatch agent with new configuration
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json || echo "Error starting CloudWatch agent" >> "$LOG_FILE"
    sudo systemctl restart amazon-cloudwatch-agent || echo "Error restarting CloudWatch agent" >> "$LOG_FILE"
 
    echo "User data script completed." >> "$LOG_FILE"
EOF
}

resource "aws_launch_template" "webapp_launch_template" {
  name          = "webapp-launch-template"
  image_id      = var.ami_id
  instance_type = var.ec2_instance_type
  key_name      = var.ec2_launch_template_ssh_key

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.public_subnets[0].id
    security_groups             = [aws_security_group.webapp_sg.id]
  }

  user_data = base64encode(local.user_data)

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = var.ec2_instance_volume_size
      volume_type           = var.ec2_volumetype
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.ec2_key.arn
    }
  }

  tags = {
    Name = "webapp_instance"
  }
}
