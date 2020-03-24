resource "aws_s3_bucket" "books_bucket" {
  bucket = "bielosx-books-storage-bucket-${var.region}"
  force_destroy = true
}
