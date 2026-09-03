terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.58.0"
    }
  }

  required_version = ">= 1.15.8"
}

provider "aws" {
  region = "us-east-1"
}

variable "domain" {
  type    = string
  default = "yuratab.pp.ua"
}

variable "ssh_allowed_ips" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "ssh_private_key_path" {
  type    = string
  default = "~/.ssh/terraform-key"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/terraform-key.pub"
}

module "ec2" {
  source = "./modules/ec2"

  ec2_type             = "t2.micro"
  ssh_allowed_ips      = var.ssh_allowed_ips
  ssh_public_key_path  = var.ssh_public_key_path
  ssh_private_key_path = var.ssh_private_key_path
  user_data_file_path  = "${path.cwd}/bootstrap.bash"
  gateway = {
    id  = module.vpc.igw_id
    arn = module.vpc.igw_arn
  }
  subnet_id                = module.vpc.public_subnets[0]
  should_create_elastic_ip = true
  vpc_id                   = module.vpc.vpc_id
  profile                  = aws_iam_instance_profile.ec2_profile.name

  initial_files = {
    "docker/docker-compose.yml" = "/home/ubuntu/docker/docker-compose.yml"
    ".env"                      = "/home/ubuntu/.env"
    "postinstall.bash"          = "/home/ubuntu/postinstall.bash"
  }
}
