#!/bin/bash

SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "grafana-admin-credentials" --query 'SecretString' --output text --profile $AWS_PROFILE)

if [ $? -ne 0 ] || [ -z "$SECRET_JSON" ]; then
    echo "Grafana credentials not found. Creating a new one..."
    grafana_username=$(LC_CTYPE=C tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 8)
    grafana_password=$(LC_CTYPE=C tr -dc 'a-zA-Z0-9!@#$%^&*()_+' </dev/urandom | head -c 12)
else
    echo "Grafana credentials found in AWS Secrets Manager."
    grafana_username=$(echo "$SECRET_JSON" | grep -oP '"grafana_username":"\K[^"]+')
    grafana_password=$(echo "$SECRET_JSON" | grep -oP '"grafana_password":"\K[^"]+')
    grafana_password=$(echo -e "$grafana_password")
fi

# Output the credentials
echo "Username: $grafana_username"
echo "Password: $grafana_password"
