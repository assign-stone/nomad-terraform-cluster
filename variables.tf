variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for Amazon Linux 2023"
  type        = string
  default     = "ami-08982f1c5bf93d976"
}

variable "server_instance_type" {
  description = "EC2 instance type for Nomad server"
  type        = string
  default     = "t3.medium"
}

variable "client_instance_type" {
  description = "EC2 instance type for Nomad clients"
  type        = string
  default     = "t3.medium"
}

variable "client_count" {
  description = "Number of Nomad client nodes"
  type        = number
  default     = 1
}

variable "key_name" {
  description = "Name of the EC2 Key Pair to use for SSH access"
  type        = string
}

variable "allowed_cidr" {
  description = "CIDR block allowed to access Nomad UI, app, and SSH"
  type        = string
  default     = "103.133.67.106/32"
}

variable "nomad_version" {
  description = "Nomad version"
  type        = string
  default     = "1.8.0"
}
