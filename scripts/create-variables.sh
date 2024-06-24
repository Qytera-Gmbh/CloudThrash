#!/bin/bash

pushd $(dirname $0) > /dev/null

. ./variables.sh

cat > terraform/terraform.tfvars <<EOL
aws_profile = "$AWS_PROFILE"
aws_region = "$AWS_REGION"
ecr_repository = "$ECR_REPOSITORY"
s3_bucket_name = "$S3_BUCKET_NAME"
aws_account_id = "$AWS_ACCOUNT_ID"

slave_memory = $SLAVE_MEMORY
slave_cpu = $SLAVE_CPU
slave_count = $SLAVE_COUNT
EOL

popd > /dev/null
