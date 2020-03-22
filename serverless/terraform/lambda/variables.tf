variable "region" {
  type = string
}

variable "role" {}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "books_bucket_name" {
  type = string
}
