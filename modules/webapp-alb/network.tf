# ----------------------------------------------------------------------------------------------------------------------
# VPC
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = merge(var.tags, {
    Name = "main"
  })
}

# ----------------------------------------------------------------------------------------------------------------------
# GATEWAYS
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name = "main"
  })
}

resource "aws_eip" "this" {
  vpc = true
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = aws_subnet.public_1.id
}

# ----------------------------------------------------------------------------------------------------------------------
# ROUTING
# Public subnets connect to internet gateway
# Private subnets connect to NAT gateway (or not for isolated)
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = var.tags
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this.id
  }
  tags = var.tags
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "compute_11" {
  subnet_id      = aws_subnet.compute_11.id
  route_table_id = aws_route_table.private.id
}

# ----------------------------------------------------------------------------------------------------------------------
# SUBNETS
# We need at least 2 public subnets for ALB
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.this.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name = "public-1"
  })
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.this.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name = "public-2"
  })
}

resource "aws_subnet" "compute_11" {
  vpc_id            = aws_vpc.this.id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.11.0/24"
  tags = merge(var.tags, {
    Name = "compute-11"
  })
}
