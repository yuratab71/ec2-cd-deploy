resource "aws_ecr_repository" "ghostfolio" {
  name                 = "ghostfolio"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
  }

  image_scanning_configuration {
    scan_on_push = false
  }
}
