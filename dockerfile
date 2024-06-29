FROM maven:3.8.5-openjdk-17-slim

RUN apt-get update && \
    apt-get install -y python3-pip jq dos2unix && \
    pip3 install awscli

WORKDIR /app

COPY simulation/pom.xml /app
RUN mvn dependency:go-offline

COPY /simulation/src /app/src
RUN mvn clean install -DskipTests

COPY docker/entrypoint.sh /app
RUN dos2unix ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
