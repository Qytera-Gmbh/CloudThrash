#!/bin/bash

# Function to check if a command is installed
check_command() {
  if command -v $1 &> /dev/null
  then
    echo "$1 is installed."
  else
    echo "$1 is not installed."
    exit 1
  fi
}

# Check if AWS CLI is installed
check_command aws

# Check if Docker is installed
check_command docker

# Check if Docker is running
if docker info &> /dev/null
then
    echo "Docker is running."
else
    echo "Docker is not running."
    exit 1
fi

echo "All checks passed."
