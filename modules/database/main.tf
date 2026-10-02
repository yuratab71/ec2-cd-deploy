terraform {
  required_version = ">= 1.15.8"
}

resource "aws_security_group" "db" {
  name   = "db"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
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

resource "aws_db_subnet_group" "db" {
  name       = "pg"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "db" {
  allocated_storage      = 10
  identifier             = "ghostfolio-pg"
  db_subnet_group_name   = aws_db_subnet_group.db.id
  engine                 = "postgres"
  engine_version         = "14"
  instance_class         = "db.t3.micro"
  username               = var.db_user_name
  password               = var.db_password
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = true
  skip_final_snapshot    = true
}
