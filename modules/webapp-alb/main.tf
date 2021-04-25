# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module uses 0.12 syntax, which means it is not compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = "~> 0.12.30"
}

provider "aws" {
  region  = "us-east-1"
  version = "~> 3.0"
}

# ----------------------------------------------------------------------------------------------------------------------
# ALB
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_lb" "this" {
  name               = "endpoint"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_to_alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  tags               = var.tags
}

resource "aws_lb_target_group" "this" {
  port     = var.target_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id
  tags     = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# EC2
# ----------------------------------------------------------------------------------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
}

data "cloudinit_config" "this" {
  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/configure_webserver.sh", {
      port = var.target_port
    })
  }
}

resource "aws_launch_configuration" "this" {
  name_prefix      = "lc-compute"
  image_id         = data.aws_ami.ubuntu.id
  instance_type    = "t2.micro"
  key_name         = "pokus"
  security_groups  = [aws_security_group.compute.id]
  user_data_base64 = data.cloudinit_config.this.rendered

  root_block_device {
    encrypted = true
  }

  ebs_block_device {
    device_name = "sdz"
    encrypted   = true
    volume_size = 8
  }
  # required when used together with asg
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  # explicitly depend on launch config's name so that asg gets redeployed on lc change
  name                 = "asg-${aws_launch_configuration.this.name}"
  desired_capacity     = var.desired_capacity
  min_size             = var.min_size
  max_size             = var.max_size
  health_check_type    = "ELB"
  launch_configuration = aws_launch_configuration.this.name
  target_group_arns    = [aws_lb_target_group.this.arn]
  vpc_zone_identifier  = [aws_subnet.compute_11.id]

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  # when replacing this asg, create replacement first and delete original after
  lifecycle {
    create_before_destroy = true
  }
}
