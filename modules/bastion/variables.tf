variable "ec2_type" {
  type    = string
  default = "t2.micro"
}

variable "elastic_ip" {
  type    = string
  default = null
}

variable "ssh_allowed_ips" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "ssh_public_key_path" {
  type = string
}

variable "ssh_private_key_path" {
  type = string
}

variable "gateway" {
  type = object({
    id  = string
    arn = string
  })
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "profile" {
  type    = string
  default = null
}
