terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# SUBNET A AND SUBNET B CREATED IN DIFFERENT AVAILABILITY ZONES
resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "SUBNET-A"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "SUBNET-B"
  }
}

#CREATE SERVERS ON EACH SUBNETS

resource "aws_instance" "server_a" {
  ami           = "ami-0dee22c13ea7a9a67"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.subnet_a.id

  tags = {
    Name        = "Server-A-subnet-a"
  }
# SERVER-A: WILL IGNORE DRIFT ON THE INSTANCE TYPE
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [
      instance_type,
    ]
  }
}

resource "aws_instance" "server_b" {
  ami           = "ami-0c7632fb77f35db43"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.subnet_b.id

  tags = {
    Name        = "Server-B-subnet-b"
  }
# SERVER-B: NO IGNORE RULES
  lifecycle {
    prevent_destroy = true
  }
}