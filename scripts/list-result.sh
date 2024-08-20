#!/bin/bash

pushd $(dirname $0) > /dev/null

. ./variables.sh

pushd ../terraform > /dev/null
PREFIX=$(terraform output -raw s3_prefix)
popd > /dev/null

FAILURE_FILE="failure"
SUCCESS_FILE="success"

# List all objects under the prefix
object_list=$(aws s3api list-objects-v2 --bucket "$S3_BUCKET_NAME" --prefix "$PREFIX" --profile "$AWS_PROFILE" --query 'Contents[].Key' --output text)

# Initialize exit status
exit_status=2

# Loop through objects and identify the correct folder
echo "Checking result of the test run $PREFIX"
for object in $object_list; do
    if [[ "$object" == *"/$FAILURE_FILE" ]]; then
        echo "${object%/*}/ - failure"
        exit_status=1
    elif [[ "$object" == *"/$SUCCESS_FILE" ]]; then
        echo "${object%/*}/ - success"
        exit_status=0
    fi
done

echo "Test run result: $exit_status"

# Exit with the appropriate status code
popd > /dev/null

exit $exit_status
