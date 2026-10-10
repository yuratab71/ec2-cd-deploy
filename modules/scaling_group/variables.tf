variable "ec2_id" {
  description = "id of instance from what the AMI will be created"
  type        = string
}

variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "vpc_public_subnets" {
  description = "List of VPC public subnets"
  type        = list(string)
}

variable "vpc_private_subnets" {
  description = "List of VPC private subnets"
  type        = list(string)
}

variable "domain_name" {
  description = "Domain name"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone id"
  type        = string
}

variable "function_name" {
  description = "Lambda function name"
  type        = string
}

variable "function_arn" {
  description = "Lambda function arn"
  type        = string
}
