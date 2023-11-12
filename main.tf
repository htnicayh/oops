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
  tags = {
    Name = "project-vpc"
  }
}

resource "aws_subnet" "public-subnet-01" {
  vpc_id = aws_vpc.project-vpc.id
  availability_zone = var.AZ_PUBLIC_01
  cidr_block = var.PUBLIC_CIDR_01

  tags = {
    Name = "public-subnet-01"
  }
}

resource "aws_subnet" "public-subnet-02" {
  vpc_id = aws_vpc.project-vpc.id
  availability_zone = var.AZ_PUBLIC_02
  cidr_block = var.PUBLIC_CIDR_02

  tags = {
    Name = "public-subnet-02"
  }
}

resource "aws_internet_gateway" "project-igw" {
  vpc_id = aws_vpc.project-vpc.id

  tags = {
    Name = "project-igw"
  }
}

resource "aws_route_table" "project-public-rtb" {
  vpc_id = aws_vpc.project-vpc.id

  route {
    cidr_block = var.ANYWHERE_CIDR
    gateway_id = aws_internet_gateway.project-igw.id
  }

  tags = {
    Name = "project-public-rtb"
  }
}

resource "aws_route_table_association" "public-rtb-associate-subnet-01" {
  subnet_id = aws_subnet.public-subnet-01.id
  route_table_id = aws_route_table.project-public-rtb.id
}

resource "aws_route_table_association" "public-rtb-associate-subnet-02" {
  subnet_id = aws_subnet.public-subnet-02.id
  route_table_id = aws_route_table.project-public-rtb.id
}

resource "aws_security_group" "gs-sg" {
  name = "gs-sg"
  description = "Security group for GS"
  vpc_id = aws_vpc.project-vpc.id

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

  tags = {
    Name = "gs-sg"
  }
}

resource "aws_security_group" "gr-sg" {
  name = "gr-sg"
  description = "Security group for GR"
  vpc_id = aws_vpc.project-vpc.id

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

  tags = {
    Name = "gr-sg"
  }
}

resource "aws_security_group" "be-sg" {
  name = "be-sg"
  description = "Security group for BE"
  vpc_id = aws_vpc.project-vpc.id

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

  tags = {
    Name = "be-sg"
  }
}

resource "aws_instance" "gs-instance" {
  ami = var.DEFAULT_AMI
  instance_type = var.PROVIDER_INSTANCE_TYPE
  key_name = var.KEY_PAIR

  subnet_id = aws_subnet.public-subnet-01.id  
  vpc_security_group_ids = [aws_security_group.gs-sg.id]
  associate_public_ip_address = true

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