output "security_group_id" {
  value = aws_security_group.jump_server.id
}

output "id" {
  description = "Bastion host id"
  value       = aws_instance.jump_server.id
}
