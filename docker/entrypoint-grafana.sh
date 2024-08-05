#!/bin/sh

HOST=$1
PORT=$2
shift 2
CMD="$@"

while ! nc -z $HOST $PORT; do
  echo "Waiting for $HOST:$PORT to be available..."
  service networking restart
  sleep 1
done

echo "$HOST:$PORT is available, starting Grafana..."
exec $CMD
