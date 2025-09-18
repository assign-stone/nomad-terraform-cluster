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
