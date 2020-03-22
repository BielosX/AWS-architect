#! /bin/bash

zip -r lambda.zip src --junk-paths
version=$2
aws s3 cp lambda.zip "s3://${1}/${version}/lambda.zip"
aws lambda update-function-code \
    --function-name books_lambda \
    --s3-bucket $1 \
    --s3-key "${version}/lambda.zip" \
    --publish
rm lambda.zip
