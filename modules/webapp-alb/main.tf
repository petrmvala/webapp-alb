# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module uses 0.12 syntax, which means it is not compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = "~> 0.12.24"
}

provider "aws" {
  region  = "us-east-1"
  version = "~> 3.0"
}


# ----------------------------------------------------------------------------------------------------------------------
# SECURITY
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "public_to_alb" {
  name        = "public-to-alb"
  description = "Allow all public HTTP(S) traffic to ALB"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP to ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS to ALB"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow access out for all resources (this AWS default is reset by TF)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "public-to-alb"
  })
}

resource "aws_security_group" "compute" {
  name        = "compute"
  description = "Compute instances SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTP access from ALB"
    from_port       = var.target_port
    to_port         = var.target_port
    protocol        = "tcp"
    security_groups = [aws_security_group.public_to_alb.id]
  }

  ingress {
    description = "SSH access from everywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow access out for all resources (this AWS default is reset by TF)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "compute"
  })
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
  protocol = var.terminate_ssl == false ? "HTTPS" : "HTTP"
  vpc_id   = aws_vpc.this.id
  tags     = var.tags
}

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = aws_instance.this.id
  port             = var.target_port
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

resource "aws_instance" "this" {
  instance_type          = "t2.micro"
  key_name               = "pokus"
  ami                    = data.aws_ami.ubuntu.id
  subnet_id              = aws_subnet.compute_11.id
  vpc_security_group_ids = [aws_security_group.compute.id]

  user_data = <<-EOF
              #!/bin/bash
              echo Hi, there! > index.html
              nohup busybox httpd -f -p "${var.target_port}" &
              EOF

  tags = var.tags
}

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
