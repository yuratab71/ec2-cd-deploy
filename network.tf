module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.2"

  region = "us-east-1"

  name = "ghostfolio-vpc"

  enable_nat_gateway = true

  azs = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]

  enable_network_address_usage_metrics = false

  public_subnets  = ["10.0.1.0/24"]
  private_subnets = ["10.0.2.0/24"]

  map_public_ip_on_launch = true

  create_database_subnet_group = true
  database_subnets             = ["10.0.3.0/24", "10.0.4.0/24"]

  create_private_nat_gateway_route = false
}



# MAIN EC2 DNS EIP CONFIG
resource "aws_route53_zone" "default" {
  name = var.domain
}

resource "aws_eip" "ip" {
  domain = "vpc"

  depends_on = [module.vpc]
}

resource "aws_eip_association" "ip" {
  instance_id   = module.ec2.id
  allocation_id = aws_eip.ip.id
}

resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.default.zone_id
  name    = var.domain
  type    = "A"
  ttl     = 60
  records = [aws_eip.ip.public_ip]
}

output "nameservers" {
  description = "Domain name nameservers"
  value       = aws_route53_zone.default.name_servers
}

output "ec2_ip" {
  value       = aws_eip.ip.public_ip
  description = "EC2 instance ip address"
}

# JUMP SERVER DNS EIP CONFIG
resource "aws_route53_zone" "jump" {
  name = var.jump_domain
}

resource "aws_eip" "jump_eip" {
  domain = "vpc"

  depends_on = [module.vpc]
}

resource "aws_eip_association" "jump_ip" {
  instance_id   = module.bastion.id
  allocation_id = aws_eip.jump_eip.id
}

resource "aws_route53_record" "jump" {
  zone_id = aws_route53_zone.jump.zone_id
  name    = var.jump_domain
  type    = "A"
  ttl     = 60
  records = [aws_eip.jump_eip.public_ip]
}

output "jump_nameservers" {
  description = "Jump server nameservers"
  value       = aws_route53_zone.jump.name_servers
}

output "jump_server_ip" {
  value       = aws_eip.jump_eip.public_ip
  description = "Jump server public ip address"
}
