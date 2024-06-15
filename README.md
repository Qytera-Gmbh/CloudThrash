# Test Execution

Local test execution:

```bash
./mvnw gatling:test
```

AWS test execution:

Deploy docker Image to ECR, create ECR repository if necessary:

```bash
./scripts/docker/docker-deployment.sh
```

Create ECS Fargate infrastructure:

```bash
cd scripts/terraform
terraform init
terraform apply --auto-approve
```

Cleanup:

```bahs
cd scripts
./clean-s3.sh
cd terraform
terraform destroy --auto-approve
```
