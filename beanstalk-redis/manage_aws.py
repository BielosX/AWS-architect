#!/usr/bin/env python

import subprocess
import argparse
import os

def run_cmd(cmd):
    print(' '.join(cmd))
    cp = subprocess.run(cmd, check=True, encoding='UTF-8', stderr=subprocess.STDOUT)
    print(cp.stdout)
    cp.check_returncode()

def create_stack(stack_name, template_file, app_name, bucket_name, env_name):
    cmd = ["aws", "cloudformation", "create-stack",
            "--stack-name", stack_name,
            "--template-body", "file://{}".format(template_file),
            "--parameters",
            "ParameterKey=ApplicationName,ParameterValue={}".format(app_name),
            "ParameterKey=DeployBucketName,ParameterValue={}".format(bucket_name),
            "ParameterKey=EnvName,ParameterValue={}".format(env_name)]
    run_cmd(cmd)

def wait_stack_create_complete(stack_name):
    cmd = ["aws", "cloudformation", "wait", "stack-create-complete", "--stack-name", stack_name]
    run_cmd(cmd)


def describe_stack(stack_name):
    cmd = ["aws", "cloudformation", "describe-stacks", "--stack-name", stack_name]
    run_cmd(cmd)

def new_stack(stack_name, app_name, bucket_name, env_name):
    try:
        create_stack(stack_name, 'app.yaml', app_name, bucket_name, env_name)
        wait_stack_create_complete(stack_name)
        describe_stack(stack_name)
    except subprocess.CalledProcessError:
        print("AWS command failed")
    except Exception as ex:
        print("Exception of type {} occurred".format(type(ex)))

def create_app_version(app_name, bucket_name, jar_name, version_label):
    cmd = ["aws", "elasticbeanstalk", "create-application-version",
            "--application-name", app_name,
            "--source-bundle", "S3Bucket={},S3Key={}".format(bucket_name, jar_name),
            "--version-label", version_label]
    run_cmd(cmd)

def update_env_version(app_name, env_name, version_label):
    cmd = ["aws", "elasticbeanstalk", "update-environment",
            "--application-name", app_name,
            "--version-label", version_label,
            "--environment-name", env_name]
    run_cmd(cmd)

def copy_to_s3(bucket_name, jar_path):
    (_, file_name) = os.path.split(jar_path)
    cmd = ["aws", "s3", "cp", jar_path, "s3://{}/{}".format(bucket_name,file_name)]
    run_cmd(cmd)

def deploy_version(app_name, bucket_name, jar_path, env_name, version_label):
    try:
        (_, jar_name) = os.path.split(jar_path)
        copy_to_s3(bucket_name, jar_path)
        create_app_version(app_name, bucket_name, jar_name, version_label)
        update_env_version(app_name, env_name, version_label)
    except subprocess.CalledProcessError:
        print("AWS command failed")
    except Exception as ex:
        print("Exception of type {} occurred".format(type(ex)))


parser = argparse.ArgumentParser(description='Manages AWS CloudFormation Stack.')
parser.add_argument('func', choices=['create', 'deploy'])
parser.add_argument('--stack-name', default='myAwesomeStack')
parser.add_argument('--bucket-name', default='my-deployment-bucket')
parser.add_argument('--app-name', default='myAwesomeApp')
parser.add_argument('--env-name', default='myEnvName')
parser.add_argument('--jar-path', default='build/libs/beanstalk-redis-all.jar')
parser.add_argument('--app-version', default='1.0')
args = vars(parser.parse_args())
func = args['func']

functions = {
        'create': lambda: new_stack(args['stack_name'], args['app_name'], args['bucket_name'], args['env_name']),
        'deploy': lambda: deploy_version(args['app_name'], args['bucket_name'], args['jar_path'], args['env_name'], args['app_version'])
        }

functions[func]()
