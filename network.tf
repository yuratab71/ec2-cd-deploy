resource "aws_vpc" "default" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "default" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }
}

resource "aws_route_table_association" "default" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.default.id
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
