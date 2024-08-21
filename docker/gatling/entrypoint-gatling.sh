#!/bin/bash

echo "IS_LEADER: $IS_LEADER"

cleanup() {
  echo "SIGTERM received, performing cleanup..."
  
  # Stop background processes
  echo "Stopping telegraf..."
  pkill telegraf

  # Kill Maven immediately
  echo "Killing Maven..."
  kill -9 "$MAVEN_PID"
  wait "$MAVEN_PID"

  # Upload the results to S3
  echo "Uploading results to S3..."
  for file in $(find ./target/gatling -type f -name simulation.log); do
    aws s3 cp $file s3://$S3_BUCKET_NAME/$S3_PREFIX/${TASK_ID}.log
  done

  # Check if this is the leader task
  if [ "$IS_LEADER" = "true" ]; then
    echo "This is the leader task, creating the report..."
    ./create-report.sh "abortion"
  fi

  echo "Cleanup completed. Exiting."
  exit 0  # Ensure the script exits immediately
}

trap 'cleanup' SIGTERM

service nscd start &&
while ! nc -z graphite.loadtest 2003; do
  echo "Waiting for graphite.loadtest:2003 to be available..."
  service nscd restart
  sleep 1
done

service nscd stop
echo "graphite.loadtest:2003 is available, starting load test..."

# Start Telegraf with the config file
mkdir -p /var/log/telegraf
telegraf --config /etc/telegraf/telegraf.conf &

# Fetch ECS metadata
ECS_METADATA=$(curl -s http://169.254.170.2/v2/metadata) # internal AWS IP
TASK_ID=$(echo $ECS_METADATA | jq -r '.TaskARN' | awk -F '/' '{print $NF}')
echo "TASK_ID: $TASK_ID"

# Set AWS region (if not already set by the environment)
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}

# Execute the main task
echo "Executing main task..."
rm -rf ./target || true
mvn gatling:test -Dgatling.noReports=true -Dgatling.data.graphite.rootPathPrefix=${GATLING_PREFIX} &
MAVEN_PID=$!  # Capture Maven's process ID

# Wait for Maven to complete
wait "$MAVEN_PID"

# Upload the results to S3
echo "Uploading results to S3..."
for file in $(find ./target/gatling -type f -name simulation.log); do
  aws s3 cp $file s3://$S3_BUCKET_NAME/$S3_PREFIX/${TASK_ID}.log
done

# Check if this is the leader task
if [ "$IS_LEADER" = "true" ]; then
  echo "This is the leader task, creating the report..."
  ./create-report.sh
fi
