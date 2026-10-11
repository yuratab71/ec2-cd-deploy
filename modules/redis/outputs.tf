output "redis_host" {
  value = aws_elasticache_replication_group.redis.configuration_endpoint_address
}

output "security_group_id" {
  value = aws_security_group.redis.id
}
