terraform {
  required_version = ">= 1.15.8"
}

data "aws_ami" "ubuntu" {
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

resource "aws_key_pair" "deployer" {
  key_name   = "terraform-key"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_security_group" "ec2" {
  name   = "ec2"
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

resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.ec2_type
  subnet_id              = var.subnet_id
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ec2.id]

  iam_instance_profile = var.profile

  tags = {
    Name = "Ubuntu EC2 instance"
  }

  user_data = file("${var.user_data_file_path}")
}

resource "null_resource" "files" {
  for_each = var.initial_files

  depends_on = [aws_instance.ec2]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/terraform-key")
    host        = aws_instance.ec2.public_ip
  }

  provisioner "file" {
    source      = each.key
    destination = each.value
  }

}

resource "aws_eip" "ip" {
  count = var.should_create_elastic_ip ? 1 : 0

  instance = aws_instance.ec2.id

  domain = "vpc"

  depends_on = [var.gateway]
}

resource "aws_eip_association" "ip" {
  count = var.should_create_elastic_ip ? 1 : 0

  instance_id   = aws_instance.ec2.id
  allocation_id = aws_eip.ip[0].id
}

output "elastic_ip" {
  value = var.should_create_elastic_ip ? aws_eip.ip[0].public_ip : null
}

