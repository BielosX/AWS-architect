import json
import boto3
import re
import os
import botocore

def get_object(object_summary):
    body = json.loads(object_summary.get()['Body'].read())
    body['bookId'] = object_summary.key
    return body

def handle_list(bucket):
    return {
            'statusCode': 200,
            'body': json.dumps(list(map(lambda obj: get_object(obj), bucket.objects.all())))
            }

def handle_get(params, bucket):
    book_id = params['book_id']
    try:
        obj = bucket.Object(book_id)
        body = json.loads(obj.get()['Body'].read().decode('utf-8'))
        body['bookId'] = book_id
        return {'statusCode': 200, 'body': json.dumps(body)}
    except botocore.exceptions.ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == '404':
            return {'statusCode': 404, 'body': json.dumps('Not found')}
        else:
            return {'statusCode': 500, 'body': json.dumps('Internal Server Error')}

def handle_post(params, bucket):
    return {
            'statusCode': 200,
            'body': json.dumps('Hello')
            }


handlers = [
        (('GET', re.compile('/books/(?P<book_id>\d+)')), handle_get),
        (('GET', re.compile('/books')), lambda params,bucket: handle_list(bucket)),
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
