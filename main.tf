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

resource "aws_vpc" "cicd-vpc" {
  cidr_block = var.VPC_CIDR
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "cicd-vpc"
  }
}

resource "aws_subnet" "public-subnet-01" {
  vpc_id = aws_vpc.cicd-vpc.id
  availability_zone = var.AZ_PUBLIC_01
  cidr_block = var.PUBLIC_CIDR_01

  tags = {
    Name = "public-subnet-01"
  }
}

resource "aws_subnet" "public-subnet-02" {
  vpc_id = aws_vpc.cicd-vpc.id
  availability_zone = var.AZ_PUBLIC_02
  cidr_block = var.PUBLIC_CIDR_02

  tags = {
    Name = "public-subnet-02"
  }
}

resource "aws_internet_gateway" "project-igw" {
  vpc_id = aws_vpc.cicd-vpc.id

  tags = {
    Name = "project-igw"
  }
}

resource "aws_route_table" "project-public-rtb" {
  vpc_id = aws_vpc.cicd-vpc.id

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

resource "aws_security_group" "gitlab-sg" {
  name = "gitlab-sg"
  description = "Security group for Gitlab server"
  vpc_id = aws_vpc.cicd-vpc.id

  ingress {
    from_port = 8090
    to_port = 8090
    protocol = "tcp"
    cidr_blocks = [var.ANYWHERE_CIDR]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [var.ANYWHERE_CIDR]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.MY_IP]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [var.ANYWHERE_CIDR]
  }

  tags = {
    Name = "gitlab-sg"
  }
}

resource "aws_security_group" "runner-sg" {
  name = "runner-sg"
  description = "Security group for Runner & Registry"
  vpc_id = aws_vpc.cicd-vpc.id

  ingress {
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = [var.ANYWHERE_CIDR]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [var.ANYWHERE_CIDR]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.MY_IP]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [var.ANYWHERE_CIDR]
  }

  tags = {
    Name = "runner-sg"
  }
}

resource "aws_security_group" "backend-sg" {
  name = "backend-sg"
  description = "Security group for Backend Web APIs"
  vpc_id = aws_vpc.cicd-vpc.id

  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    cidr_blocks = [var.ANYWHERE_CIDR]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [var.ANYWHERE_CIDR]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.MY_IP]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [var.ANYWHERE_CIDR]
  }

  tags = {
    Name = "backend-sg"
  }
}

resource "aws_security_group_rule" "inbound_ssh_gr" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend-sg.id
  security_group_id        = aws_security_group.runner-sg.id
}

resource "aws_security_group_rule" "inbound_ssh_be" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.runner-sg.id
  security_group_id        = aws_security_group.backend-sg.id
}

# resource "aws_instance" "gitlab-instance" {
#   ami = var.DEFAULT_AMI
#   instance_type = var.PROVIDER_INSTANCE_TYPE
#   key_name = var.KEY_PAIR

#   subnet_id = aws_subnet.public-subnet-01.id  
#   vpc_security_group_ids = [aws_security_group.gitlab-sg.id]
#   associate_public_ip_address = true

#   user_data = <<-EOF
#     #!/bin/bash
#     apt-get update
#     apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
#     curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
#     add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
#     apt-get update
#     apt-get install docker-ce docker-ce-cli containerd.io -y
#     curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#     chmod +x /usr/local/bin/docker-compose
#     mkdir -p /home/app/gitlab
#   EOF

#   tags = {
#     Name = "gitlab-instance"
#   }
# }

# resource "aws_instance" "runner-instance" {
#   ami = var.DEFAULT_AMI
#   instance_type = var.PROVIDER_INSTANCE_TYPE
#   key_name = var.KEY_PAIR

#   subnet_id = aws_subnet.public-subnet-01.id  
#   vpc_security_group_ids = [aws_security_group.runner-sg.id]
#   associate_public_ip_address = true

#   user_data = <<-EOF
#     #!/bin/bash
#     apt-get update
#     apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y 
#     curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
#     add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
#     apt-get update
#     apt-get install docker-ce docker-ce-cli containerd.io -y
#     curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#     chmod +x /usr/local/bin/docker-compose
#     curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash
#     apt-get install gitlab-runner -y
#     apt-cache madison gitlab-runner
#     gitlab-runner -version
#     usermod -aG docker gitlab-runner
#     usermod -aG sudo gitlab-runner
#     mkdir -p /home/docker/registry && chmod -R 777 /home/docker/registry && cd /home/docker/registry 
#     mkdir certs data
#     apt get update
#     apt-get install openssl -y
#   EOF

#   tags = {
#     Name = "runner-instance"
#   }
# }

# resource "aws_instance" "backend-instance" {
#   ami = var.DEFAULT_AMI
#   instance_type = var.PROVIDER_INSTANCE_TYPE
#   key_name = var.KEY_PAIR

#   subnet_id = aws_subnet.public-subnet-02.id  
#   vpc_security_group_ids = [aws_security_group.backend-sg.id]
#   associate_public_ip_address = true

#   user_data = <<-EOF
#     #!/bin/bash
#     apt-get update
#     apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
#     curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
#     add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
#     apt-get update
#     apt-get install docker-ce docker-ce-cli containerd.io -y
#     curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#     chmod +x /usr/local/bin/docker-compose
#   EOF

#   tags = {
#     Name = "backend-instance"
#   }
# }