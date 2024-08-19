#!/bin/bash

pushd $(dirname $0) > /dev/null

. ./variables.sh
./stop-test.sh

pushd ../terraform > /dev/null

terraform destroy -auto-approve

aws ecr describe-repositories --repository-names $ECR_REPOSITORY --profile $AWS_PROFILE --region $AWS_REGION && \
aws ecr delete-repository --repository-name $ECR_REPOSITORY --profile $AWS_PROFILE --region $AWS_REGION --force

popd > /dev/null
popd > /dev/null
