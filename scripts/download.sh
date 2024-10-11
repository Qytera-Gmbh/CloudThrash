#!/bin/bash

pushd $(dirname $0)

. ./variables.sh

pushd ..  > /dev/null

# Check if FILE_LOCATION environment variable is set
if [ -z "$FILE_LOCATION" ]; then
    echo "Error: FILE_LOCATION environment variable is not set."
    exit 1
fi

# Create downloads directory if it doesn't exist
mkdir -p ./downloaded-reports

# Download the file from S3 to the downloads directory
last_segment=$(basename "$FILE_LOCATION")
aws s3 cp "s3://$S3_BUCKET_NAME/${FILE_LOCATION}report.7z" "downloaded-reports/$last_segment/report.7z" --region $AWS_REGION --profile $AWS_PROFILE

# Check if the download was successful
if [ $? -eq 0 ]; then
    echo "File successfully downloaded to downloaded-reports/$last_segment/report.7z"
    7z x "downloaded-reports/$last_segment/report.7z" -o"downloaded-reports/$last_segment" -aoa
else
    echo "Error: Failed to download file from $FILE_LOCATION"
    exit 1
fi

popd > /dev/null
popd > /dev/null
