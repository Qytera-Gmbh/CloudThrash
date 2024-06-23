# Distributed Load Testing with Gatling

This project demonstrates distributed load testing with Gatling. It uses Gatling to simulate a load on a web application. The Gatling load test is executed on AWS Fargate.

## Requirements

-   Java 17
-   Maven
-   Docker
-   Terraform
-   AWS Account
-   AWS CLI
-   bash (on Windows a git bash is enough)

## Setup

AWS credentials must be set in your home. Add the following content to `~/.aws/credentials`:

```properties
[default]
aws_access_key_id=<access-key>
aws_secret_access_key=<secret>
```

and also a config file is required `~/.aws/config`:

```properties
[default]
region=us-east-1
```

This is required to properly setup your AWS access.

## Test Execution

This section will explain all steps required to start the load test.

### Configuration

There are some configurations done inside `/scripts/variables.sh`. Especially the values

```bash
AWS_PROFILE="besessener"
AWS_REGION="us-east-1"
```

must be changed to your needs. The profile might be `default` in most cases, just like it was defined before in the `~/.aws/credentials` and `~/.aws/config` files.

The other variables should be adapted to your needs:

_TODO: add table with description when ready_

### Local

```bash
cd simulation
./mvnw gatling:test
```

### AWS Cloud

```bash
./scripts/run-test.sh
```

Stop the test execution and delete not required resources (done automatically after test execution):

```bash
./scripts/stop-test.sh
```

cleanup (remaining resources like ECR and S3):

```bash
./scripts/delete-all-resources.sh
```
