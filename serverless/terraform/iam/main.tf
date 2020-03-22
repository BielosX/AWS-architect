data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_iam_role" {
  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "s3_full_access_attach" {
  role = "${aws_iam_role.lambda_iam_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
