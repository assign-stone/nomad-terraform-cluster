terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.67.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"
  allowed_cidr = var.allowed_cidr
}

module "nomad_server" {
  source          = "./modules/nomad-server"
  subnet_id       = module.vpc.public_subnet_id
  ami_id          = var.ami_id
  instance_type   = var.server_instance_type
  security_group_ids = [module.vpc.nomad_sg_id]
  key_name            = var.key_name
}

module "nomad_client" {
  source          = "./modules/nomad-client"
  subnet_id       = module.vpc.private_subnet_id
  ami_id          = var.ami_id
  instance_type   = var.client_instance_type
  client_count    = var.client_count
  security_group_ids = [module.vpc.nomad_sg_id]
  key_name            = var.key_name
}

output "nomad_server_public_ip" {
  value = module.nomad_server.public_ip
}
