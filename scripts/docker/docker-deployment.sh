#!/bin/bash

# pushd current file dir
pushd $(dirname $0) > /dev/null
pushd .. > /dev/null
pushd .. > /dev/null

# Variables
AWS_PROFILE="besessener"
AWS_REGION="us-east-1"
ECR_REPOSITORY="loadtesting"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)

# Create ECR repository if it doesn't exist
aws ecr describe-repositories --repository-names $ECR_REPOSITORY --profile $AWS_PROFILE --region $AWS_REGION || \
aws ecr create-repository --repository-name $ECR_REPOSITORY --profile $AWS_PROFILE --region $AWS_REGION

# Authenticate Docker to ECR
aws ecr get-login-password --profile $AWS_PROFILE --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build, tag, and push the Docker image
docker build -t gatling-distributed-load-testing .
docker tag gatling-distributed-load-testing:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest

popd > /dev/null
popd > /dev/null
popd > /dev/null
