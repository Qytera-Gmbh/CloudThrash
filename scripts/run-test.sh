#!/bin/bash

set -e

pushd $(dirname $0) > /dev/null

. ./variables.sh
./create-variables.sh
./deploy-docker-container.sh

pushd terraform > /dev/null

terraform init
terraform apply -auto-approve

# Extract the ECS cluster name and AWS region from the Terraform output
ECS_CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)

# Function to get the running task ARN
get_running_task_arn() {
  TASK_ARN=$(aws ecs list-tasks \
    --cluster $ECS_CLUSTER_NAME \
    --family loadtesting-task \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --query 'taskArns[0]' \
    --output text)
}

# Wait for the task to start
echo "Waiting for the task to start..."
while true; do
  get_running_task_arn
  if [ "$TASK_ARN" != "None" ]; then
    echo "Found running ECS task with ARN: $TASK_ARN"
    break
  fi
  echo "No running task found yet. Checking again in 10 seconds..."
  sleep 10
done

# Function to check the status of the ECS task
check_task_status() {
  TASK_STATUS=$(aws ecs describe-tasks \
    --cluster $ECS_CLUSTER_NAME \
    --tasks $TASK_ARN \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --query 'tasks[0].lastStatus' \
    --output text)
  echo "Current task status: $TASK_STATUS"
}

# Initial task status check
check_task_status

# Wait for the task to complete
while [[ "$TASK_STATUS" != "STOPPED" ]]; do
  sleep 10
  check_task_status
done

popd > /dev/null

./stop-test.sh

popd > /dev/null
