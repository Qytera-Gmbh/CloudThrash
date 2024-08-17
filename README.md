# Gatling Distributed Performance Testing

This repository provides a framework for distributed performance testing using Gatling, Graphite, and Grafana. It leverages Docker for containerized environments and Terraform for infrastructure as code.

## Features

- **Gatling**: Used for load testing and performance benchmarking.
- **Graphite**: Time-series database for storing performance metrics.
- **Grafana**: Visualization tool to create dynamic dashboards for performance monitoring.
- **Docker**: Containerized environments for easy deployment.
- **Terraform**: Infrastructure as Code (IaC) to automate the setup of cloud resources.

## Repository Structure

- **docker/**: Contains Dockerfiles for setting up Gatling, Grafana, and Graphite.
  - `dockerfile.gatling`: Dockerfile for Gatling.
  - `dockerfile.grafana`: Dockerfile for Grafana.
  - `dockerfile.graphite`: Dockerfile for Graphite.
  - `gatling/`: Scripts related to running and configuring Gatling inside a Docker container.
  - `grafana/`: Configuration files for Grafana dashboards and data sources.
  - `graphite/`: Configuration for Graphite.

- **scripts/**: Shell scripts for managing the testing environment and processes.
  - `run-test.sh`: Script to deploy Docker containers, create infrastructure, and run the Gatling test.
  - `stop-test.sh`: Script to stop the test and clean up resources.
  - `deploy-docker-container.sh`: Script to deploy the Docker containers.
  - `list-results.sh`: Script to list the test results.
  - `variables.sh`: Contains environment variables used across scripts.

- **simulation/**: Contains the Gatling simulation setup.
  - `src/test/java/simulations/BasicSimulation.java`: Example Gatling simulation.
  - `pom.xml`: Maven configuration file.

- **terraform/**: Terraform configurations for setting up cloud infrastructure.
  - `main.tf`: Main Terraform configuration file.
  - `modules/`: Contains reusable Terraform modules for ECS, network, and S3 setups.

## Getting Started

### Prerequisites

- Docker
- Terraform
- Bash Shell

### Setup

1. **Clone the Repository**

   ```bash
   git clone https://github.com/besessener/Gatling-Distributed-Performance-Testing.git
   cd Gatling-Distributed-Performance-Testing
   ```

2. **Run the Test**

   The `run-test.sh` script will handle the entire process, including deploying Docker containers, creating the necessary cloud infrastructure with Terraform, and executing the Gatling performance test:

   ```bash
   ./scripts/run-test.sh
   ```

   The script includes the following steps:
   - Initializes and applies Terraform configurations to create the required cloud infrastructure.
   - Deploys Docker containers for Gatling, Grafana, and Graphite.
   - Runs the Gatling performance test and collects the results.

3. **Monitor Results**

   Access Grafana to monitor the test results:

   ```bash
   # Replace with your Grafana URL from the grafana task in ECS
   http://<grafana_url>:3000
   ```

4. **Stop the Test and Clean Up**

   After the test is complete, you can stop the test and clean up resources using the `stop-test.sh` script:

   ```bash
   ./scripts/stop-test.sh
   ```
## Architecture

This project leverages AWS ECS (Elastic Container Service) with Fargate instances to create load with Gatling (Java).

Technology Map:

![](docs/technology-map.drawio.png)

Architecture Diagram:

// TODO

## Customization

- Modify the Gatling simulations in the `simulation/src/test/java/simulations/` directory to fit your testing scenarios.
- Update the Grafana dashboards in the `docker/grafana/` directory to customize the performance metrics visualization.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.

## License

This project is licensed under the MIT License.
