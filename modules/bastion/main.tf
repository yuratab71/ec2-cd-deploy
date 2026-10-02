terraform {
  required_version = ">= 1.15.8"
}

data "aws_ami" "jump_server_ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "jump_server_key" {
  key_name   = "bastion-key"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_security_group" "jump_server" {
  name   = "jump_server"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_ips
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2"
  }
}

resource "aws_instance" "jump_server" {
  ami                    = data.aws_ami.jump_server_ubuntu.id
  instance_type          = var.ec2_type
  subnet_id              = var.subnet_id
  key_name               = aws_key_pair.jump_server_key.key_name
  vpc_security_group_ids = [aws_security_group.jump_server.id]

  iam_instance_profile = var.profile

  tags = {
    Name = "Ubuntu EC2 instance"
  }
}

output "id" {
  description = "Bastion host id"
  value       = aws_instance.jump_server.id
}
