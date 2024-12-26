resource "aws_autoscaling_group" "webapp_asg" {
  name                = "webapp-auto-scaling-group"
  desired_capacity    = 3
  min_size            = 3
  max_size            = 5
  vpc_zone_identifier = aws_subnet.public_subnets[*].id
  launch_template {
    id      = aws_launch_template.webapp_launch_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.webapp_tg.arn]

  tag {
    key                 = "Name"
    value               = "webapp_instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}


# Create CloudWatch Alarms for Scaling Policies
resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_name          = "scale_up_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = var.upscale_threshold
  alarm_description   = "Alarm to get trigerred when CPU is above the threshold"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_name          = "scale_down_alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = var.downscale_threshold
  alarm_description   = "Alarm to get trigerred when CPU is below the threshold%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}

# Scale Down Policy
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.webapp_asg.name
}

# Scale Up Policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.webapp_asg.name
}
