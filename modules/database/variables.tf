variable "private_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "db_user_name" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type    = string
  default = "admin"
}

variable "security_groups" {
  type = list(string)
}
