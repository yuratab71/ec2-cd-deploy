variable "private_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "allowed_ips" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "db_user_name" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type    = string
  default = "admin"
}
