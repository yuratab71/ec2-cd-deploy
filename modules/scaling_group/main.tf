terraform {
  required_version = ">= 1.15.8"
}

data "aws_caller_identity" "this" {}

# ===========================================
# AUTOSCALING GROUP
# ===========================================

resource "aws_ami_from_instance" "this" {
  name               = "AMI from Ghostfolion main EC2 instance"
  source_instance_id = var.ec2_id
}

resource "aws_security_group" "sg" {
  name   = "SG"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "this" {
  name_prefix   = "ghostfolio"
  image_id      = aws_ami_from_instance.this.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.sg.id
  ]

  network_interfaces {
    associate_public_ip_address = true
  }

  user_data = base64encode(<<-EOF
  #!/bin/bash

  cd /home/ubuntu
  docker compose up -d
  sudo systemctl restart nginx
EOF
  )
}

resource "aws_autoscaling_policy" "up" {
  name                   = "AGS_policy_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "aws_autoscaling_policy" "down" {
  name                   = "AGS_policy_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "AGS_CPU_policy"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    target_value = 70
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "AGS_policy_memory_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "System/Linux"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_actions       = [aws_autoscaling_policy.up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_low" {
  alarm_name          = "AGS_policy_memory_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "System/Linux"
  period              = "300"
  statistic           = "Average"
  threshold           = "40"
  alarm_actions       = [aws_autoscaling_policy.down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }
}

resource "aws_autoscaling_group" "this" {
  name             = "Ghostfolio AGS"
  max_size         = 3
  min_size         = 1
  desired_capacity = 1

  health_check_grace_period = 300
  health_check_type         = "ELB"

  force_delete        = true
  vpc_zone_identifier = var.vpc_private_subnets

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_attachment" "this" {
  autoscaling_group_name = aws_autoscaling_group.this.name
  lb_target_group_arn    = aws_lb_target_group.this.arn
}

# ===========================================
# LOAD BALANCER
# ===========================================

resource "aws_security_group" "lb" {
  name   = "ghostfolio"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "this" {
  name     = "ghostfolio"
  port     = 80
  protocol = "HTTP"

  vpc_id = var.vpc_id

  health_check {
    protocol = "HTTP"
    path     = "/api/v1/health"
  }
}

resource "aws_lb" "this" {
  name               = "ghostfolio"
  load_balancer_type = "application"
  internal           = false

  subnets = var.vpc_public_subnets

  security_groups = [
    aws_security_group.lb.id
  ]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = aws_acm_certificate.this.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_listener_certificate" "this" {
  listener_arn    = aws_alb_listener.https.arn
  certificate_arn = aws_acm_certificate.this.arn
}

resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  ttl             = 60
  zone_id         = var.hosted_zone_id
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

# ===========================================
# DISCORD NOTIFICATIONS
# ===========================================

locals {
  region = "us-east-1"
  name   = "ec2-cpu-monitoring"
  alarms = {
    cpu = {
      name                = "${local.name}-1"
      metric_name         = "Errors"
      comparison_operator = "GreaterThanThreshold"
      description         = "AGS CPU usage alarm"
      dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.this.name
      }
  } }
}

resource "aws_sns_topic" "this" {
  name = "EC2-alarm-sns"
}



resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.this.arn
}

resource "aws_sns_topic_subscription" "this" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "lambda"
  endpoint  = var.function_arn

  depends_on = [
  aws_lambda_permission.sns]
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.alarms

  alarm_name          = "${each.value.name}-alarm"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = 1
  metric_name         = each.value.metric_name
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = 90
  datapoints_to_alarm = 1
  alarm_actions       = [aws_sns_topic.this.arn]
  alarm_description   = each.value.description
  treat_missing_data  = "notBreaching"

  dimensions = each.value.dimensions
}
