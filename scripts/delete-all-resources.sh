#!/bin/bash

pushd $(dirname $0) > /dev/null

. ./variables.sh
./stop-test.sh

pushd ../terraform > /dev/null

aws s3 rm s3://$S3_BUCKET_NAME --recursive --profile $AWS_PROFILE
terraform destroy -target=module.s3 -auto-approve

aws ecr describe-repositories --repository-names $ECR_REPOSITORY --profile $AWS_PROFILE --region $AWS_REGION && \
aws ecr delete-repository --repository-name $ECR_REPOSITORY --profile $AWS_PROFILE --region $AWS_REGION --force



#!/bin/bash

# Set the tag key and value
TAG_KEY="Project"
TAG_VALUE="LoadTesting"

# Get the list of resources with the specified tag
resources=$(aws resourcegroupstaggingapi get-resources --tag-filters Key=$TAG_KEY,Values=$TAG_VALUE --query 'ResourceTagMappingList[*].ResourceARN' --output text)

# Function to delete EC2 instances
delete_ec2_instances() {
  for resource in $resources; do
    if [[ $resource == arn:aws:ec2:* ]]; then
      instance_id=$(echo $resource | cut -d '/' -f2)
      echo "Terminating EC2 instance: $instance_id"
      aws ec2 terminate-instances --instance-ids $instance_id
    fi
  done
}

# Function to delete S3 buckets
delete_s3_buckets() {
  for resource in $resources; do
    if [[ $resource == arn:aws:s3:::* ]]; then
      bucket_name=$(echo $resource | cut -d ':' -f6)
      echo "Deleting S3 bucket: $bucket_name"
      aws s3 rb s3://$bucket_name --force
    fi
  done
}

# Function to deregister ECS task definitions
deregister_ecs_task_definitions() {
  for resource in $resources; do
    if [[ $resource == arn:aws:ecs:*:task-definition/* ]]; then
      task_definition=$(echo $resource | cut -d '/' -f2)
      echo "Deregistering ECS task definition: $task_definition"
      aws ecs deregister-task-definition --task-definition $task_definition
    fi
  done
}

# Function to delete ECS services
delete_ecs_services() {
  for resource in $resources; do
    if [[ $resource == arn:aws:ecs:*:service/* ]]; then
      cluster_name=$(echo $resource | cut -d '/' -f2)
      service_name=$(echo $resource | cut -d '/' -f3)
      echo "Deleting ECS service: $service_name in cluster: $cluster_name"
      aws ecs delete-service --cluster $cluster_name --service $service_name --force
    fi
  done
}

# Function to delete VPCs
delete_vpcs() {
  for resource in $resources; do
    if [[ $resource == arn:aws:ec2:*:vpc/* ]]; then
      vpc_id=$(echo $resource | cut -d '/' -f2)
      echo "Deleting VPC: $vpc_id"
      aws ec2 delete-vpc --vpc-id $vpc_id
    fi
  done
}

# Function to delete Route Tables
delete_route_tables() {
  for resource in $resources; do
    if [[ $resource == arn:aws:ec2:*:route-table/* ]]; then
      route_table_id=$(echo $resource | cut -d '/' -f2)
      echo "Deleting Route Table: $route_table_id"
      aws ec2 delete-route-table --route-table-id $route_table_id
    fi
  done
}

# Function to delete Subnets
delete_subnets() {
  for resource in $resources; do
    if [[ $resource == arn:aws:ec2:*:subnet/* ]]; then
      subnet_id=$(echo $resource | cut -d '/' -f2)
      echo "Deleting Subnet: $subnet_id"
      aws ec2 delete-subnet --subnet-id $subnet_id
    fi
  done
}

# Function to delete Internet Gateways
delete_internet_gateways() {
  for resource in $resources; do
    if [[ $resource == arn:aws:ec2:*:internet-gateway/* ]]; then
      igw_id=$(echo $resource | cut -d '/' -f2)
      echo "Deleting Internet Gateway: $igw_id"
      aws ec2 delete-internet-gateway --internet-gateway-id $igw_id
    fi
  done
}

# Function to delete Security Groups
delete_security_groups() {
  for resource in $resources; do
    if [[ $resource == arn:aws:ec2:*:security-group/* ]]; then
      sg_id=$(echo $resource | cut -d '/' -f2)
      echo "Deleting Security Group: $sg_id"
      aws ec2 delete-security-group --group-id $sg_id
    fi
  done
}

# Function to delete ECS Clusters
delete_ecs_clusters() {
  for resource in $resources; do
    if [[ $resource == arn:aws:ecs:*:cluster/* ]]; then
      cluster_name=$(echo $resource | cut -d '/' -f2)
      echo "Deleting ECS cluster: $cluster_name"
      aws ecs delete-cluster --cluster $cluster_name
    fi
  done
}

# Call the functions for each resource type
delete_ec2_instances
delete_s3_buckets
deregister_ecs_task_definitions
delete_ecs_services
delete_vpcs
delete_route_tables
delete_subnets
delete_internet_gateways
delete_security_groups
delete_ecs_clusters

echo "Deletion process completed."





popd > /dev/null
popd > /dev/null
