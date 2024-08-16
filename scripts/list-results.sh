#!/bin/bash

pushd $(dirname $0) > /dev/null

. ./variables.sh

# Define variables
pushd ../terraform > /dev/null
PREFIX=$(terraform output -raw s3_prefix)
PREFIX=${PREFIX%/*}/  # Remove last segment
PREFIX=${PREFIX%/*}/  # Remove another segment
popd > /dev/null

FAILURE_FILE="failure"
SUCCESS_FILE="success"

# List all objects under the modified prefix
object_list=$(aws s3api list-objects-v2 --bucket "$S3_BUCKET_NAME" --prefix "$PREFIX" --profile "$AWS_PROFILE" --query 'Contents[].Key' --output text)

# Initialize flags to track whether success or failure was found
found_success=false
found_failure=false

# Loop through objects and identify the correct folders
for object in $object_list; do
    if [[ "$object" == *"/$FAILURE_FILE" ]]; then
        echo "${object%/*}/ - failure"
        found_failure=true
    elif [[ "$object" == *"/$SUCCESS_FILE" ]]; then
        echo "${object%/*}/ - success"
        found_success=true
    fi
done

# Handle cases where neither file is found
if ! $found_success && ! $found_failure; then
    echo "No success or failure files found under the prefix: $PREFIX"
fi

popd > /dev/null
