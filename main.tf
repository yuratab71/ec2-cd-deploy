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
  user_data_file_path  = "${path.cwd}/user_data.bash"
  gateway = {
    id  = module.vpc.igw_id
    arn = module.vpc.igw_arn
  }
  subnet_id                = module.vpc.public_subnets[0]
  should_create_elastic_ip = false
  elastic_ip               = aws_eip.ip.public_ip
  vpc_id                   = module.vpc.vpc_id
  profile                  = aws_iam_instance_profile.ec2_profile.name

  initial_files = {
    "docker-compose.yml"       = "/home/ubuntu/docker-compose.yml"
    ".env"                     = "/home/ubuntu/.env"
    "user_data.bash"           = "/home/ubuntu/user_data.bash"
    "postinstall.bash"         = "/home/ubuntu/postinstall.bash"
    "archive-backup.bash"      = "/home/ubuntu/archive-backup.bash"
    "setup-cron-archiver.bash" = "/home/ubuntu/setup-cron-archiver.bash"
  }
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "cloudwatch"
  role = aws_iam_role.ecr_access.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents"
      ]

      Resource = "*"
    }]
  })
}

module "storage" {
  source = "./modules/storage"
}

module "redis" {
  source = "./modules/redis"

  vpc_id             = module.vpc.vpc_id
  allowed_ips        = ["10.0.1.0/24"]
  private_subnet_ids = module.vpc.private_subnets
}
