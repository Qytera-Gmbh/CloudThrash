FROM maven:3.8.5-openjdk-17-slim

# Install necessary packages
RUN apt-get update && \
    apt-get install -y python3-pip jq && \
    pip3 install awscli

# Set the working directory
WORKDIR /app

# Copy the Maven project files
COPY pom.xml /app
RUN mvn dependency:go-offline

# Copy the source files
COPY /src /app/src
RUN mvn clean install -DskipTests

# Ensure the entry point script has executable permissions
RUN chmod +x src/entrypoint.sh

# Set the entry point to the script in its current location
ENTRYPOINT ["./src/entrypoint.sh"]
