FROM golang:1.22-alpine as builder

RUN apk add --no-cache git make
WORKDIR /go/src/github.com/influxdata/telegraf
RUN git clone https://github.com/influxdata/telegraf.git . && \
    make

FROM maven:3.8.5-openjdk-17-slim

RUN apt-get update && \
    apt-get install -y python3-pip jq dos2unix curl && \
    pip3 install awscli

WORKDIR /app

COPY --from=builder /go/src/github.com/influxdata/telegraf/telegraf /usr/bin/telegraf

COPY simulation/pom.xml /app
RUN mvn dependency:go-offline

COPY /simulation/src /app/src
RUN mvn install

COPY docker/entrypoint.sh /app
RUN dos2unix ./entrypoint.sh && chmod +x ./entrypoint.sh

COPY docker/telegraf.conf /etc/telegraf/telegraf.conf
RUN dos2unix /etc/telegraf/telegraf.conf

ENTRYPOINT ["./entrypoint.sh"]
