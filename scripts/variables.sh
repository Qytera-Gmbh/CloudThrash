#!/bin/bash

AWS_PROFILE="besessener"
AWS_REGION="us-east-1"
ECR_REPOSITORY="loadtesting"
S3_BUCKET_NAME="gatling-distributed-loadtesting-bucket"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)

SLAVE_MEMORY=8192
SLAVE_CPU=2048
SLAVE_COUNT=1
MASTER_MEMORY=8192
MASTER_CPU=2048
