terraform {
  required_version = ">= 1.15.8"
}


resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "ghostfolio-redis"
  description          = "Ghostfolio redis cluster"

  engine             = "redis"
  node_type          = "cache.t3.micro"
  num_cache_clusters = 1

  apply_immediately  = true
  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]
}

resource "aws_elasticache_subnet_group" "redis" {
  name = "redis"

  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "redis" {
  name   = "redis-security-group"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
