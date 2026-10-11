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

variable "jump_domain" {
  type    = string
  default = "yuratab-db.pp.ua"
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

variable "discord_webhook_url" {
  type      = string
  sensitive = true
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
    "docker-compose.yml" = "/home/ubuntu/docker-compose.yml"
    ".env"               = "/home/ubuntu/.env"
    "user_data.bash"     = "/home/ubuntu/user_data.bash"
    "postinstall.bash"   = "/home/ubuntu/postinstall.bash"
  }
}

module "bastion" {
  source = "./modules/bastion"

  ec2_type            = "t2.micro"
  ssh_allowed_ips     = var.ssh_allowed_ips
  ssh_public_key_path = var.ssh_public_key_path
  gateway = {
    id  = module.vpc.igw_id
    arn = module.vpc.igw_arn
  }
  subnet_id = module.vpc.public_subnets[0]
  vpc_id    = module.vpc.vpc_id
  profile   = aws_iam_instance_profile.ec2_profile.name
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

module "redis" {
  source             = "./modules/redis"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  security_groups    = [module.bastion.security_group_id, module.ec2.security_group_id, module.ASG.security_group_id]
}

module "db" {
  source             = "./modules/database"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.database_subnets
  db_user_name       = "ghostfolio"
  db_password        = "ghostfolio"
  security_groups    = [module.bastion.security_group_id, module.ec2.security_group_id, module.ASG.security_group_id]
}

module "lambda" {
  source = "./modules/lambda"

  function = {
    name         = "AGS_CPU_NOTIFICATION"
    source_path  = "cpu-usage-notification.js"
    archive_path = ".cpu-usage-notification.zip"
  }

  env = {
    DISCORD_WEBHOOK_URL = var.discord_webhook_url
  }
}

module "ASG" {
  source              = "./modules/scaling_group"
  ec2_id              = module.ec2.id
  vpc_public_subnets  = module.vpc.public_subnets
  vpc_private_subnets = module.vpc.private_subnets
  vpc_id              = module.vpc.vpc_id
  domain_name         = var.domain
  hosted_zone_id      = aws_route53_zone.default.id
  function_name       = module.lambda.lambda_name
  function_arn        = module.lambda.lambda_arn
}
