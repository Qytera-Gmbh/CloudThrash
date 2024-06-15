#!/bin/bash

AWS_PROFILE="besessener"

aws s3 rm s3://gatling-distributed-loadtesting-bucket --recursive --profile $AWS_PROFILE
