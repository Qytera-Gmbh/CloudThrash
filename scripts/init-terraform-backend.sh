#!/bin/bash

. ./variables.sh

pushd ../terraform > /dev/null

# Check if the S3 bucket exists
if ! aws s3api head-bucket --bucket "$S3_TF_STATE" --region "$AWS_REGION" --profile "$AWS_PROFILE" 2>/dev/null; then
    echo "S3 bucket does not exist. Creating bucket..."
    aws s3api create-bucket --bucket "$S3_TF_STATE" --region "$AWS_REGION" --profile "$AWS_PROFILE"
else
    echo "S3 bucket already exists. Skipping creation."
fi

# Check if the DynamoDB table exists
if ! aws dynamodb describe-table --table-name "$DYNAMO_TF_STATE" --region "$AWS_REGION" --profile "$AWS_PROFILE" 2>/dev/null; then
    echo "DynamoDB table does not exist. Creating table..."
    aws dynamodb create-table \
        --table-name "$DYNAMO_TF_STATE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE"
else
    echo "DynamoDB table already exists. Skipping creation."
fi


terraform init \
  -backend-config="region=$AWS_REGION" \
  -backend-config="profile=$AWS_PROFILE" \
  -backend-config="bucket=$S3_TF_STATE" \
  -backend-config="dynamodb_table=$DYNAMO_TF_STATE"

popd > /dev/null
