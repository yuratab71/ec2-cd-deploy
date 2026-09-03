module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  region = "us-east-1"

  name = "ghostfolio-vpc"

  enable_nat_gateway = true

  azs = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]

  enable_network_address_usage_metrics = false

  public_subnets = ["10.0.1.0/24"]

  map_public_ip_on_launch = true

  create_private_nat_gateway_route = false
}

resource "aws_route53_zone" "default" {
  name = var.domain
}

resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.default.zone_id
  name    = var.domain
  type    = "A"
  ttl     = 60
  records = [module.ec2.elastic_ip]
}

output "nameservers" {
  description = "Domain name nameservers"
  value       = aws_route53_zone.default.name_servers
}
