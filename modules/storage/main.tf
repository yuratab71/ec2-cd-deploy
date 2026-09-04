terraform {
  required_version = ">= 1.15.8"
}

resource "aws_s3_bucket" "backups" {
  bucket = "ghostfolio-db-backups-storage"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "glacier-backups-archive"
    status = "Enabled"

    filter {}

    transition {
      days          = 7
      storage_class = "GLACIER"
    }

    expiration {
      days = 30
    }
  }
}
