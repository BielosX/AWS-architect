variable "deployment_tag" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "max_instances" {
  type = number
}

variable "min_instances" {
  type = number
}

variable "subnets" {
  type = list(string)
}

variable "key_pair" {
  type = string
}