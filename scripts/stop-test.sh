#!/bin/bash

pushd $(dirname $0) > /dev/null

. ./variables.sh

stop_tasks_with_same_timestamp() {
  declare -A seen_tags
  declare -A timestamp_map
  declare -A tasks_grouped_by_timestamp
  local count=1
  local stop_all=false

  # Check if --all flag is provided
  if [[ "$1" == "--all" ]]; then
    stop_all=true
  fi

  TASK_ARNS=$(aws ecs list-tasks \
    --cluster $ECS_CLUSTER_NAME \
    --desired-status RUNNING \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --query 'taskArns[*]' \
    --output text)

  for TASK_ARN in $TASK_ARNS; do
    TAGS_JSON=$(aws ecs list-tags-for-resource \
      --resource-arn $TASK_ARN \
      --region $AWS_REGION \
      --profile $AWS_PROFILE \
      --output json)

    # Extract specific tags using a regex pattern matching
    PROJECT=$(echo $TAGS_JSON | grep -Po '"key":\s*"Project",\s*"value":\s*"\K[^"]+')
    APP_NAME=$(echo $TAGS_JSON | grep -Po '"key":\s*"app_name",\s*"value":\s*"\K[^"]+')
    UNIQUE_TIMESTAMP=$(echo $TAGS_JSON | grep -Po '"key":\s*"unique_timestamp",\s*"value":\s*"\K[^"]+')
    USER=$(echo $TAGS_JSON | grep -Po '"key":\s*"user",\s*"value":\s*"\K[^"]+')

    if [ -n "$UNIQUE_TIMESTAMP" ]; then
      # Map the unique_timestamp to the task ARN
      tasks_grouped_by_timestamp[$UNIQUE_TIMESTAMP]="${tasks_grouped_by_timestamp[$UNIQUE_TIMESTAMP]} $TASK_ARN"

      # Only display unique timestamps and associated details
      if [ -z "${seen_tags[$UNIQUE_TIMESTAMP]}" ]; then
        seen_tags[$UNIQUE_TIMESTAMP]=1
        timestamp_map[$count]=$UNIQUE_TIMESTAMP
        echo "($count)"
        echo "Project: $PROJECT"
        echo "App Name: $APP_NAME"
        echo "Unique Timestamp: $UNIQUE_TIMESTAMP"
        echo "User: $USER"
        echo "-----------------------------"
        count=$((count + 1))
      fi
    fi
  done

  # Stop all tasks if --all flag is provided
  if $stop_all; then
    echo "Stopping all tasks..."
    for UNIQUE_TIMESTAMP in "${!tasks_grouped_by_timestamp[@]}"; do
      for TASK_ARN in ${tasks_grouped_by_timestamp[$UNIQUE_TIMESTAMP]}; do
        aws ecs stop-task \
          --cluster $ECS_CLUSTER_NAME \
          --task $TASK_ARN \
          --region $AWS_REGION \
          --profile $AWS_PROFILE
        echo "Stopped Task ARN: $TASK_ARN"
      done
    done
  else
    # Prompt for user input
    if [ $count -gt 1 ]; then
      echo "Select a test-execution by number to stop all associated tasks: "
      read -r selected_number

      # Retrieve the selected unique timestamp
      SELECTED_UNIQUE_TIMESTAMP="${timestamp_map[$selected_number]}"

      if [ -n "$SELECTED_UNIQUE_TIMESTAMP" ]; then
        echo "Stopping all tasks with Unique Timestamp: $SELECTED_UNIQUE_TIMESTAMP"
        for TASK_ARN in ${tasks_grouped_by_timestamp[$SELECTED_UNIQUE_TIMESTAMP]}; do
          aws ecs stop-task \
            --cluster $ECS_CLUSTER_NAME \
            --task $TASK_ARN \
            --region $AWS_REGION \
            --profile $AWS_PROFILE
          echo "Stopped Task ARN: $TASK_ARN"
        done
      else
        echo "Invalid selection."
      fi
    else
      echo "No tasks with unique timestamps were found."
    fi
  fi
}

# Pass all script arguments to the function
stop_tasks_with_same_timestamp "$@"

popd > /dev/null
