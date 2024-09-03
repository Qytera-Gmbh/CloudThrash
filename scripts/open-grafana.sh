#!/bin/bash

pushd $(dirname $0) > /dev/null

. ./variables.sh
. ./get-grafana-credentials.sh

SERVICE_NAME="grafana-service"
TASK_ARN=$(aws ecs list-tasks --cluster "$ECS_CLUSTER_NAME" --service-name "$SERVICE_NAME" --query 'taskArns[0]' --output text --profile $AWS_PROFILE)
ENI_ID=$(aws ecs describe-tasks --cluster "$ECS_CLUSTER_NAME" --tasks "$TASK_ARN" --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text --profile $AWS_PROFILE)
GRAFANA_IP=$(aws ec2 describe-network-interfaces --network-interface-ids "$ENI_ID" --query 'NetworkInterfaces[0].Association.PublicIp' --output text --profile $AWS_PROFILE)
GRAFANA_PORT="3000"

if [ -z "$GRAFANA_IP" ]; then
    echo "Failed to retrieve Grafana public IP address."
    exit 1
fi

GRAFANA_URL="http://$GRAFANA_IP:$GRAFANA_PORT"

xdg-open "$GRAFANA_URL" &>/dev/null || open "$GRAFANA_URL" &>/dev/null || start "$GRAFANA_URL"

popd > /dev/null
