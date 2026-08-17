variable "ec2_type" {
  type    = string
  default = "t2.micro"
}


variable "should_create_elastic_ip" {
  type    = bool
  default = false
}

variable "env_path" {
  type = string
}

variable "docker_compose_path" {
  type = string
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

variable "user_data_file_path" {
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
