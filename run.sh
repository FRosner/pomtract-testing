#!/bin/bash

if ! docker compose version > /dev/null 2>&1; then
    echo "Error: Docker Compose is not available. Please make sure Docker Compose is installed and working."
    exit 1
fi

PACT_BROKER_URL="http://localhost:9292"
MAX_RETRIES=30
RETRY_INTERVAL=2

echo "Starting..."
docker compose up -d

echo "Waiting for Pact Broker to be ready..."
retries=0
while [ $retries -lt $MAX_RETRIES ]; do
    if curl -s -f "${PACT_BROKER_URL}" > /dev/null 2>&1; then
        echo "Pact Broker is now available at: ${PACT_BROKER_URL}"
        break
    fi
    retries=$((retries + 1))
    if [ $retries -eq $MAX_RETRIES ]; then
        echo "Error: Pact Broker failed to become ready within ${MAX_RETRIES} attempts"
        echo "Stopping and removing containers..."
        docker compose down
        exit 1
    fi
    echo "Waiting for Pact Broker to be ready... (Attempt $retries of $MAX_RETRIES)"
    sleep $RETRY_INTERVAL
done

read -p "Press Enter to tear down the stack and exit..."

echo "Stopping and removing containers..."
docker compose down

echo "Cleanup complete!"
