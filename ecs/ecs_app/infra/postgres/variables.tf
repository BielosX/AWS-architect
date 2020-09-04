variable "master_username" {
  type = string
  default = "master"
}

variable "db_subnets" {
  type = list(string)
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}