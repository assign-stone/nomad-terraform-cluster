variable "subnet_id" {}
variable "ami_id" {}
variable "instance_type" {}
variable "security_group_ids" {}
variable "key_name" {}

resource "aws_instance" "server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name

  user_data = file("${path.module}/../../scripts/bootstrap.sh")

  tags = {
    Name = "nomad-server"
  }
}

output "public_ip" {
  value = aws_instance.server.public_ip
}
