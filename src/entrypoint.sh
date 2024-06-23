#!/bin/bash

# Fetch ECS metadata
ECS_METADATA=$(curl -s http://169.254.170.2/v2/metadata)
TASK_ID=$(echo $ECS_METADATA | jq -r '.TaskARN' | awk -F '/' '{print $NF}')
echo "TASK_ID: $TASK_ID"

# Set AWS region (if not already set by the environment)
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}

# Function to check if all tasks are ready
check_all_tasks_ready() {
  READY_COUNT=$(aws s3 ls s3://$S3_BUCKET_NAME/gatling-results/$RUN_TIMESTAMP/ready/ | wc -l)
  echo "READY_COUNT: $READY_COUNT"
  if [ "$READY_COUNT" -eq "$TOTAL_TASKS" ]; then
    return 0
  else
    return 1
  fi
}

# Notify that this task is ready
echo "Notifying readiness..."
touch /tmp/$TASK_ID.ready
aws s3 cp /tmp/$TASK_ID.ready s3://$S3_BUCKET_NAME/gatling-results/$RUN_TIMESTAMP/ready/$TASK_ID
if [ $? -ne 0 ]; then
  echo "Failed to upload readiness file to S3" >&2
  exit 1
else
  echo "Successfully uploaded readiness file to S3"
fi
rm /tmp/$TASK_ID.ready

# Debugging: List files in S3 to verify upload
echo "Listing files in S3 bucket $S3_BUCKET_NAME:"
aws s3 ls s3://$S3_BUCKET_NAME/gatling-results/$RUN_TIMESTAMP/ready/

# Wait until all tasks are ready
while ! check_all_tasks_ready; do
  echo "Waiting for all tasks to be ready..."
  sleep 5
done

echo "All tasks are ready. Proceeding with the main task."

# Execute the main task
echo "Executing main task..."
rm -rf ./target || true
mvn gatling:test -Dgatling.noReports=true

# delete all the ready files again
aws s3 rm s3://$S3_BUCKET_NAME/gatling-results/$RUN_TIMESTAMP/ready/ --recursive

# Upload the results to S3 using the timestamp from the environment variable
echo "Uploading results to S3..."
for file in $(find ./target/gatling -type f -name simulation.log); do
  aws s3 cp $file s3://$S3_BUCKET_NAME/gatling-results/$RUN_TIMESTAMP/${TASK_ID}.log
done
