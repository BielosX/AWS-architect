variable "region" {
  type = string
  default = "eu-west-1"
}
variable "cluster_arn" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

