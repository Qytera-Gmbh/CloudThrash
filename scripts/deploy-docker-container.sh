#!/bin/bash

pushd $(dirname $0) > /dev/null

. ./variables.sh

# Check if ECR repository exists, if not create it
aws ecr describe-repositories --repository-names $ECR_REPOSITORY --profile $AWS_PROFILE --region $AWS_REGION || \
aws ecr create-repository --repository-name $ECR_REPOSITORY --profile $AWS_PROFILE --region $AWS_REGION

# Login to ECR
aws ecr get-login-password --profile $AWS_PROFILE --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

pushd .. > /dev/null

# Build, tag, and push Gatling image
docker build -t gatling-distributed-load-testing -f dockerfile.gatling .
docker tag gatling-distributed-load-testing:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:gatling-latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:gatling-latest

# Build, tag, and push Grafana image
docker build -t grafana-custom -f dockerfile.grafana .
docker tag grafana-custom:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:grafana-latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:grafana-latest

# Build the custom Docker image for Graphite
docker build -t graphite-custom -f dockerfile.graphite .
docker tag graphite-custom:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:graphite-latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:graphite-latest


popd > /dev/null
popd > /dev/null
