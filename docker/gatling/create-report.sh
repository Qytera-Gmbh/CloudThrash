#!/bin/bash

pushd $(dirname $0) > /dev/null

# Construct the S3 path
S3_PATH="s3://${S3_BUCKET_NAME}/${S3_PREFIX}"

# Define the local directory where you want to download the log files
LOCAL_DIR="./target/gatling/$UNIQUE_TIMESTAMP"

# Create the local directory if it doesn't exist
mkdir -p $LOCAL_DIR

# Function to count the number of log files in the S3 path
count_log_files_in_s3() {
  aws s3api list-objects-v2 --bucket $S3_BUCKET_NAME --prefix "${S3_PREFIX}/" --query "length(Contents[?ends_with(Key, '.log')])" --output text
}

# Wait until the number of log files in S3 is equal to TOTAL_TASKS
while true; do
  log_file_count=$(count_log_files_in_s3)
  if [ "$log_file_count" -ge "$TOTAL_TASKS" ]; then
    break
  fi
  echo "Waiting for log files... ($log_file_count/$TOTAL_TASKS)"
  sleep 10
done

# Download all .log files from the specified S3 path to the local directory
aws s3 cp $S3_PATH $LOCAL_DIR --recursive --exclude "*" --include "*.log"

# Confirm the files have been downloaded
echo "Downloaded .log files from $S3_PATH to $LOCAL_DIR"

# Create the Gatling report
mvn gatling:test -Dgatling.reportsOnly=$UNIQUE_TIMESTAMP
MVN_EXIT_CODE=$?

# Check if the Maven command was successful
if [ $MVN_EXIT_CODE -eq 0 ]; then
  # Maven succeeded
  STATUS_FILE="success"
else
  # Maven failed
  STATUS_FILE="failure"
fi

# Create an empty status file
touch $STATUS_FILE

# Compress the entire local directory using 7z
ZIP_FILE="report.7z"
7z a $ZIP_FILE $LOCAL_DIR/*

# Upload the 7z file back to S3
aws s3 cp $ZIP_FILE $S3_PATH/$ZIP_FILE

# Upload the status file to S3
aws s3 cp $STATUS_FILE $S3_PATH/$STATUS_FILE

# Clean up the status file
rm $STATUS_FILE

popd > /dev/null
