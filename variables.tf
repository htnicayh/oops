# Variables
variable "REGION" {
  description = "AWS Region"
  type = string
}

variable "VPC_CIDR" {
  description = "VPC CIDR"
  type = string
}

variable "AZ_PUBLIC_01" {
  description = "Public Subnet Region"
  type = string
}

variable "AZ_PUBLIC_02" {
  description = "Public Subnet Region"
  type = string
}

variable "PUBLIC_CIDR_01" {
  description = "Public Subnet CIDR"
  type = string
}

variable "PUBLIC_CIDR_02" {
  description = "Private Subnet CIDR"
  type = string
}

variable "MY_IP" {
  description = "My IPv4"
  type = string
}

variable "ANYWHERE_CIDR" {
  description = "Anywhere"
  type = string
}

variable "KEY_PAIR" {
  description = "Key name"
  type = string
}

variable "DEFAULT_AMI" {
  description = "AMI ID"
  type = string
}

variable "DEFAULT_INSTANCE_TYPE" {
  description = "DEFAULT INSTANCE TYPE"
  type = string
}

variable "PROVIDER_INSTANCE_TYPE" {
  description = "PROVIDER INSTANCE TYPE"
  type = string
}
