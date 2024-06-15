FROM maven:3.8.5-openjdk-17-slim

RUN apt-get update && \
    apt-get install -y python3-pip && \
    pip3 install awscli

WORKDIR /app

COPY pom.xml /app
RUN mvn dependency:go-offline

COPY /src /app/src
RUN mvn clean install -DskipTests

CMD ["echo", "running gatling tests"]
