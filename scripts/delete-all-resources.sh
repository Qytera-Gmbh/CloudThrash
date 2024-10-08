#!/bin/bash

# Initialize a variable for the -y option
auto_yes=false

# Check for the -y option
while getopts "y" opt; do
  case $opt in
    y)
      auto_yes=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

pushd $(dirname $0) > /dev/null

. ./variables.sh
./init-terraform-backend.sh

check_and_prompt_for_running_tasks() {
  declare -A seen_tags
  declare -A tasks_grouped_by_timestamp
  local found_tasks=0

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

    PROJECT=$(echo $TAGS_JSON | grep -Po '"key":\s*"Project",\s*"value":\s*"\K[^"]+')
    APP_NAME=$(echo $TAGS_JSON | grep -Po '"key":\s*"app_name",\s*"value":\s*"\K[^"]+')
    UNIQUE_TIMESTAMP=$(echo $TAGS_JSON | grep -Po '"key":\s*"unique_timestamp",\s*"value":\s*"\K[^"]+')
    USER=$(echo $TAGS_JSON | grep -Po '"key":\s*"user",\s*"value":\s*"\K[^"]+')

    if [ -n "$UNIQUE_TIMESTAMP" ]; then
      tasks_grouped_by_timestamp[$UNIQUE_TIMESTAMP]="${tasks_grouped_by_timestamp[$UNIQUE_TIMESTAMP]} $TASK_ARN"
      
      if [ -z "${seen_tags[$UNIQUE_TIMESTAMP]}" ]; then
        seen_tags[$UNIQUE_TIMESTAMP]=1
        echo "Found running task with the following details:"
        echo "Project: $PROJECT"
        echo "App Name: $APP_NAME"
        echo "Unique Timestamp: $UNIQUE_TIMESTAMP"
        echo "User: $USER"
        echo "-----------------------------"
        found_tasks=1
      fi
    fi
  done

  if [ $found_tasks -eq 1 ]; then
    if [ "$auto_yes" = true ]; then
      user_response="y"
    else
      echo "There are running tasks associated with these details. Do you want to stop them and proceed with deletion? (y/n)"
      read -r user_response
    fi

    if [[ "$user_response" =~ ^[Yy]$ ]]; then
      for UNIQUE_TIMESTAMP in "${!tasks_grouped_by_timestamp[@]}"; do
        echo "Stopping all tasks with Unique Timestamp: $UNIQUE_TIMESTAMP"
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
      echo "Deletion canceled by user."
      exit 0
    fi
  else
    echo "No running tasks with unique timestamps were found. Proceeding with resource deletion."
  fi
}

final_deletion_warning() {
  if [ "$auto_yes" = true ]; then
    final_confirmation="y"
  else
    echo ""
    echo "---------------------------------------------"
    echo "WARNING: You are about to delete all resources including:"
    echo "- Terraform-managed infrastructure"
    echo "- ECR Docker images"
    echo "- S3 buckets containing test results"
    echo "These resources will be permanently deleted and cannot be recovered."
    echo "Do you really want to proceed? (y/n)"
    read -r final_confirmation
  fi

  if [[ "$final_confirmation" =~ ^[Yy]$ ]]; then
    echo "Proceeding with deletion of all resources..."
    return 0
  else
    echo "Deletion canceled by user."
    exit 0
  fi
}

check_and_prompt_for_running_tasks

final_deletion_warning

pushd ../terraform > /dev/null

terraform destroy -auto-approve -lock=false

aws ecr describe-repositories --repository-names $ECR_REPOSITORY --profile $AWS_PROFILE --region $AWS_REGION && \
aws ecr delete-repository --repository-name $ECR_REPOSITORY --profile $AWS_PROFILE --region $AWS_REGION --force

aws s3 rm s3://$S3_TF_STATE --recursive --region $AWS_REGION --profile $AWS_PROFILE
aws s3api delete-bucket --bucket $S3_TF_STATE --region $AWS_REGION --profile $AWS_PROFILE
aws dynamodb delete-table --table-name $DYNAMO_TF_STATE --region $AWS_REGION --profile $AWS_PROFILE

popd > /dev/null
popd > /dev/null
