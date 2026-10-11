output "db_host" {
  value = aws_db_instance.db.address
}

output "security_group_id" {
  value = aws_security_group.db.id
}
