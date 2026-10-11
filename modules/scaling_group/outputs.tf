output "lb_dns_name" {
  type  = string
  value = aws_lb.this.dns_name
}

output "lb_zone_id" {
  type  = string
  value = aws_lb.this.zone_id
}

output "security_group_id" {
  type  = string
  value = aws_security_group.sg.id
}
