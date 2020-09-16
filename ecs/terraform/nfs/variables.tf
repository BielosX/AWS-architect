variable "private_subnets" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "mount_target_sg" {
  type = string
}