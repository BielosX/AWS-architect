resource "aws_s3_bucket" "books_bucket" {
  bucket = "bielosx-books-bucket-${var.region}"
  acl = "private"
}
