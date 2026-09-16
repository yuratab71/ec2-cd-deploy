output "redis_host" {
  value = aws_elasticache_replication_group.redis.configuration_endpoint_address
}
