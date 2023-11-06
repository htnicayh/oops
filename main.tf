terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# Provider
provider "aws" {
  region  = var.REGION
}

resource "aws_vpc" "project-vpc" {
  cidr_block = var.VPC_CIDR
}

resource "aws_subnet" "public-subnet-01" {
  vpc_id = aws_vpc.project-vpc.id
  availability_zone = var.AZ_PUBLIC_01
  cidr_block = var.PUBLIC_CIDR_01
}

resource "aws_subnet" "public-subnet-02" {
  vpc_id = aws_vpc.project-vpc.id
  availability_zone = var.AZ_PUBLIC_02
  cidr_block = var.PUBLIC_CIDR_02
}

resource "aws_internet_gateway" "project-igw" {
  vpc_id = aws_vpc.project-vpc.id
}

resource "aws_route_table" "project-public-rtb" {
  vpc_id = aws_vpc.project-vpc.id

  route {
    cidr_block = var.ANYWHERE_CIDR
    gateway_id = aws_internet_gateway.project-igw.id
  }
}

resource "aws_security_group" "gs-sg" {
  name = "gs-sg"
  description = "Security group for GS"

  ingress {
    from_port = 8090
    to_port = 8090
    protocol = "tcp"
    cidr_blocks = [var.ANYWHERE_CIDR]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.MY_IP]
  }
}

resource "aws_security_group" "gr-sg" {
  name = "gr-sg"
  description = "Security group for GR"

  ingress {
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = [var.ANYWHERE_CIDR]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.MY_IP]
  }
}

resource "aws_security_group" "be-sg" {
  name = "be-sg"
  description = "Security group for BE"

  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    cidr_blocks = [var.ANYWHERE_CIDR]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.MY_IP]
  }
}

resource "aws_instance" "gs-instance" {
  ami = var.DEFAULT_AMI
  instance_type = var.PROVIDER_INSTANCE_TYPE
  key_name = var.KEY_PAIR

  security_groups = [aws_security_group.gs-sg.name]

  tags = {
    Name = "gs-instance"
  }
}

# resource "aws_instance" "gr-instance" {
#   ami = var.DEFAULT_AMI
#   instance_type = var.PROVIDER_INSTANCE_TYPE
#   key_name = var.KEY_PAIR

#   security_groups = [aws_security_group.gr-sg.name]

#   tags = {
#     Name = "gr-instance"
#   }
# }

# resource "aws_instance" "be-instance" {
#   ami = var.DEFAULT_AMI
#   instance_type = var.PROVIDER_INSTANCE_TYPE
#   key_name = var.KEY_PAIR

#   security_groups = [aws_security_group.be-sg.name]

#   tags = {
#     Name = "be-instance"
#   }
# }