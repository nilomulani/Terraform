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

#CREATE INTERNET GATEWAY
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
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
  ami                         = "ami-0c7632fb77f35db43"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.subnet_a.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg_for_servers.id]
  user_data_replace_on_change = true
  user_data                   = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y apache2
    cat > /var/www/html/index.html <<'HTML'
    <!doctype html>
    <html><body>
      <h1>Hello from Ubuntu!</h1>
      <svg width="300" height="160" xmlns="http://www.w3.org/2000/svg">
        <rect width="300" height="160" fill="lightblue"/>
        <circle cx="230" cy="40" r="22" fill="gold"/>
        <path d="M0 160 L100 60 L160 120 L210 80 L300 160Z" fill="seagreen"/>
      </svg>
    </body></html>
    HTML
    systemctl enable --now apache2
  EOF

  tags = {
    Name = "Server-A-subnet-a"
  }
  # SERVER-A: WILL IGNORE DRIFT ON THE INSTANCE TYPE
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      instance_type,
    ]
  }
}

resource "aws_instance" "server_b" {
  ami                         = "ami-0c7632fb77f35db43"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.subnet_b.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg_for_servers.id]
  user_data_replace_on_change = true
  user_data                   = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y apache2
    cat > /var/www/html/index.html <<'HTML'
    <!doctype html>
    <html><body>
      <h1>Hello from Ubuntu!</h1>
      <svg width="300" height="160" xmlns="http://www.w3.org/2000/svg">
        <rect width="300" height="160" fill="lightblue"/>
        <circle cx="230" cy="40" r="22" fill="gold"/>
        <path d="M0 160 L100 60 L160 120 L210 80 L300 160Z" fill="seagreen"/>
      </svg>
    </body></html>
    HTML
    systemctl enable --now apache2
  EOF

  tags = {
    Name = "Server-B-subnet-b"
  }
  # SERVER-B: NO IGNORE RULES
  lifecycle {
    prevent_destroy = false
  }
}

#CREATE ROUTE TABLE
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
}

#ASSOCIATE OR ATTACH ROUTE TABLE WITH EACH SUBNETS
resource "aws_route_table_association" "subnet_a_association" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "subnet_b_association" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

# ADD SECURITY GROUP FOR LOAD BALANCER.
# This security group allows inbound and outbound traffic on port 80 (HTTP)
resource "aws_security_group" "sg_for_lb" {
  name        = "sg_for_lb"
  description = "Allow HTTP to LB"
  vpc_id      = aws_vpc.main.id

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

#CREATE LOAD BALANCER AND ATTACH IT TO THE SECURITY GROUP AND SUBNETS
resource "aws_lb" "main_lb" {
  name               = "main-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_for_lb.id]
  subnets            = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

  enable_deletion_protection = false

  tags = {
    Name = "main-lb"
  }
}

#CREATE SECURITY GROUP FOR SERVERS
resource "aws_security_group" "sg_for_servers" {
  name        = "sg_for_servers"
  description = "Allow HTTP from LB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_for_lb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# CREATE TARGET GROUP FOR SERVERS
resource "aws_lb_target_group" "app_tg" {
  name     = "simple-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# ATTACH SERVERS-A TO TARGET GROUP
resource "aws_lb_target_group_attachment" "server_a_attachment" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.server_a.id
  port             = 80
}

# ATTACH SERVERS-B TO TARGET GROUP
resource "aws_lb_target_group_attachment" "server_b_attachment" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.server_b.id
  port             = 80
}

# LISTENER FOR LOAD BALANCER
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}