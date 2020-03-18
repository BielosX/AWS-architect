import json
import boto3
import os
import botocore

import router

def jsonWithCode(code, body):
    return {'statusCode': code, 'body': json.dumps(body)}

def get_object(object_summary):
    body = json.loads(object_summary.get()['Body'].read())
    body['bookId'] = object_summary.key
    return body

def handle_list(bucket):
    return jsonWithCode(200, list(map(lambda obj: get_object(obj), bucket.objects.all())))

def handle_get(params, bucket):
    book_id = params['bookId']
    try:
        obj = bucket.Object(book_id)
        body = json.loads(obj.get()['Body'].read().decode('utf-8'))
        body['bookId'] = book_id
        return jsonWithCode(200, body)
    except botocore.exceptions.ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == '404':
            return jsonWithCode(404, 'Not found')
        else:
            return jsonWithCode(500, 'Internal Server Error')

def handle_post(params, bucket):
    return {
            'statusCode': 200,
            'body': json.dumps('Hello')
            }

def main(event, context):
    bucket = boto3.resource('s3').Bucket(os.environ['BUCKET_NAME'])
    method = event['httpMethod']
    path = event['path']

    r = Router()
    r.add_handler("/books/{bookId}", "GET", handle_get)
    r.add_handler("/books", "GET", lambda params,bucket: handle_list(bucket))
    r.add_handler("/books", "POST", handle_post)

    match = r.route(path, method)
    if match:
        (params, handler) = match
        return handler(params, bucket)
    else:
        return {'statusCode': 404, 'body': 'Not found'}
