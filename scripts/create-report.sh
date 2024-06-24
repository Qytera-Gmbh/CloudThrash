#!/bin/bash

pushd $(dirname $0) > /dev/null

. ./variables.sh

pushd terraform > /dev/null
current_timestamp=$(terraform output -raw current_timestamp)
popd > /dev/null
pushd ../simulation > /dev/null

# Construct the S3 path
S3_PATH="s3://${S3_BUCKET_NAME}/gatling-results/${current_timestamp}"

# Define the local directory where you want to download the log files
LOCAL_DIR="./target/gatling/$current_timestamp"

# Create the local directory if it doesn't exist
mkdir -p $LOCAL_DIR

# Download all .log files from the specified S3 path to the local directory
aws s3 cp $S3_PATH $LOCAL_DIR --recursive --exclude "*" --include "*.log" --profile $AWS_PROFILE

# Confirm the files have been downloaded
echo "Downloaded .log files from $S3_PATH to $LOCAL_DIR"

# Create the Gatling report
./mvnw gatling:test -Dgatling.reportsOnly=$current_timestamp

# Compress the entire local directory using 7z
ZIP_FILE="report.7z"
7z a $ZIP_FILE $LOCAL_DIR/*

# Upload the 7z file back to S3
aws s3 cp $ZIP_FILE $S3_PATH/$ZIP_FILE --profile $AWS_PROFILE

# Create the results directory if it doesn't exist
RESULTS_DIR="../results/$current_timestamp"
mkdir -p $RESULTS_DIR

# Copy all files from the local directory to the results directory
cp -r $LOCAL_DIR/* $RESULTS_DIR/

# Clean up
rm -rf $LOCAL_DIR
rm $ZIP_FILE

popd > /dev/null
popd > /dev/null
