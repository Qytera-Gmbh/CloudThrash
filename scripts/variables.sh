#!/bin/bash

AWS_PROFILE="besessener"
AWS_REGION="us-east-1"
ECR_REPOSITORY="loadtesting"
S3_BUCKET_NAME="cloudthrash-loadtesting"
S3_TF_STATE="cloudthrash-terraform-states"
DYNAMO_TF_STATE="terraform-lock-table"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)
ECS_CLUSTER_NAME="loadtesting-cluster"

SLAVE_MEMORY=4096
SLAVE_CPU=2048
SLAVE_COUNT=2 # vCPU quota limit needs to be considered, Grafana and Graphite will also need same amount of resources

APP_NAME="BasicLoadSimulation"

export AWS_PAGER=""
