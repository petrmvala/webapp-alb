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

