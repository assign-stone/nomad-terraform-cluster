provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"
}

module "nomad_server" {
  source          = "./modules/nomad-server"
  subnet_id       = module.vpc.public_subnet_id
  ami_id          = var.ami_id
  instance_type   = var.server_instance_type
  security_group_ids = [module.vpc.nomad_sg_id]
}

module "nomad_client" {
  source          = "./modules/nomad-client"
  subnet_id       = module.vpc.private_subnet_id
  ami_id          = var.ami_id
  instance_type   = var.client_instance_type
  client_count    = var.client_count
  security_group_ids = [module.vpc.nomad_sg_id]
}

output "nomad_server_public_ip" {
  value = module.nomad_server.public_ip
}
