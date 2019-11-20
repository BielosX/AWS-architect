#!/usr/bin/env python

import subprocess
import argparse

def run_cmd(cmd):
    print(' '.join(cmd))
    cp = subprocess.run(cmd, check=True, encoding='UTF-8', stderr=subprocess.STDOUT)
    print(cp.stdout)
    cp.check_returncode()

def create_stack(stack_name, template_file, app_name, bucket_name):
    cmd = [ "aws", "cloudformation", "create-stack",
            "--stack-name", stack_name,
            "--template-body", "file://{}".format(template_file),
            "--parameters",
            "ParameterKey=ApplicationName,ParameterValue={}".format(app_name),
            "ParameterKey=DeployBucketName,ParameterValue={}".format(bucket_name)]
    run_cmd(cmd)

def wait_stack_create_complete(stack_name):
    cmd = ["aws", "cloudformation", "wait", "stack-create-complete", "--stack-name", stack_name]
    run_cmd(cmd)


def describe_stack(stack_name):
    cmd = ["aws", "cloudformation", "describe-stacks", "--stack-name", stack_name]
    run_cmd(cmd)


parser = argparse.ArgumentParser(description='Creates AWS CloudFormation Stack.')
parser.add_argument('--stack-name', default='myAwesomeStack')
parser.add_argument('--bucket-name', default='my-deployment-bucket')
parser.add_argument('--app-name', default='myAwesomeApp')
args = vars(parser.parse_args())

try:
    stack_name = args['stack_name']
    create_stack(stack_name, 'app.yaml', args['app_name'], args['bucket_name'])
    wait_stack_create_complete(stack_name)
    describe_stack(stack_name)
except subprocess.CalledProcessError:
    print("AWS command failed")
except Exception as ex:
    print("Exception of type {} occurred".format(type(ex)))
