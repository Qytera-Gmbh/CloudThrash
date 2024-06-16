#!/bin/bash

pushd $(dirname $0) > /dev/null

. ./variables.sh

aws ecr describe-repositories --repository-names $ECR_REPOSITORY --profile $AWS_PROFILE --region $AWS_REGION || \
aws ecr create-repository --repository-name $ECR_REPOSITORY --profile $AWS_PROFILE --region $AWS_REGION

aws ecr get-login-password --profile $AWS_PROFILE --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

pushd .. > /dev/null

docker build -t gatling-distributed-load-testing .
docker tag gatling-distributed-load-testing:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest

popd > /dev/null
popd > /dev/null
