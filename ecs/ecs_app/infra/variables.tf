variable "region" {
  type = string
  default = "eu-west-1"
}
variable "cluster_name" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

