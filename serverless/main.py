import json
import boto3
import re
import os

def handle_list(bucket):
    return {
            'statusCode': 200,
            'body': json.dumps(map(bucket.objects.all(), lambda obj: obj.key))
            }

def handle_get(params, bucket):
    return {
            'statusCode': 200,
            'body': json.dumps('Hello')
            }

def handle_post(params, bucket):
    return {
            'statusCode': 200,
            'body': json.dumps('Hello')
            }


handlers = [
        (('GET', re.compile('/books')), lambda params,bucket: handle_list(bucket)),
        (('GET', re.compile('/books/(?P<book_id>)\d+')), handle_get),
        (('POST', re.compile('/books')), handle_post)
        ]

def main(event, context):
    bucket = boto3.resource('s3').Bucket(os.environ['BUCKET_NAME'])
    matched_methods = filter(lambda h: h[0][0] == event['httpMethod'], handlers)
    matches = map(lambda h: (h[0][1].match(event['path']), h[1]), matched_methods)
    matched_handlers = list(filter(lambda m: m[0] is not None, matches))
    if len(matched_handlers) == 0:
        return {
                'statusCode': 404,
                'body': json.dumps('Not found')
                }
    else:
        (m,f) = matched_handlers[0]
        return f(m.groupdict(), bucket)
