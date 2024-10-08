#!/bin/bash

AWS_PROFILE="${AWS_PROFILE:=besessener}"
AWS_REGION="${AWS_REGION:=us-east-1}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)
ECR_REPOSITORY="${ECR_REPOSITORY:=loadtesting}"
S3_BUCKET_NAME="${S3_BUCKET_NAME:=cloudthrash-loadtesting-${AWS_ACCOUNT_ID}}"
S3_TF_STATE="${S3_TF_STATE:=cloudthrash-terraform-states-${AWS_ACCOUNT_ID}}"
DYNAMO_TF_STATE="${DYNAMO_TF_STATE:=terraform-lock-table}"

ECS_CLUSTER_NAME="${ECS_CLUSTER_NAME:=loadtesting-cluster}"
SLAVE_MEMORY="${SLAVE_MEMORY:=4096}"
SLAVE_CPU="${SLAVE_CPU:=2048}"
SLAVE_COUNT="${SLAVE_COUNT:=2}" # vCPU quota limit needs to be considered, Grafana and Graphite will also need same amount of resources

APP_NAME="${APP_NAME:=BasicLoadSimulation}"
ENV_VARS="${ENV_VARS:=}"

export AWS_PAGER=""
