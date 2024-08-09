#!/bin/bash

set +e

SECRET_NAME="grafana-admin-credentials"

SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --query 'SecretString' --output text --profile $AWS_PROFILE)

if [ $? -ne 0 ] || [ -z "$SECRET_JSON" ]; then
    echo "Grafana credentials not found. Creating a new one..."
    grafana_username=$(LC_CTYPE=C tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 8)
    grafana_password=$(LC_CTYPE=C tr -dc 'a-zA-Z0-9!@#$%^&*()_+' </dev/urandom | head -c 12)
else
    echo "Grafana credentials found in AWS Secrets Manager."
    grafana_username=$(echo "$SECRET_JSON" | grep -o '"grafana_username":[^,}]*' | awk -F':' '{print $2}' | tr -d ' "')
    grafana_password=$(echo "$SECRET_JSON" | grep -o '"grafana_password":[^,}]*' | awk -F':' '{print $2}' | tr -d ' "')
fi

set -e
