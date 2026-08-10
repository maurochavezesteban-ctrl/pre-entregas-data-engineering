# 1. VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "vpc-${var.environment}"
    Environment = var.environment
  }
}

# 2. Subred Privada A
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name        = "subnet-private-a-${var.environment}"
    Environment = var.environment
  }
}

# 3. Subred Privada B
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name        = "subnet-private-b-${var.environment}"
    Environment = var.environment
  }
}

# 4a. Route Table para la Subred A
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "rt-private-a-${var.environment}"
    Environment = var.environment
  }
}

# 4b. Route Table para la Subred B
resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "rt-private-b-${var.environment}"
    Environment = var.environment
  }
}

# 5a. Asociar Subred A con su Route Table
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

# 5b. Asociar Subred B con su Route Table
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

# 6. S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  route_table_ids = [
    aws_route_table.private_a.id,
    aws_route_table.private_b.id
  ]

  tags = {
    Name        = "s3-endpoint-${var.environment}"
    Environment = var.environment
  }
}