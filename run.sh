#!/bin/bash

if ! docker compose version > /dev/null 2>&1; then
    echo "Error: docker compose is not available/working."
    exit 1
fi
if ! npm --version > /dev/null 2>&1; then
    echo "Error: npm is not available/working."
    exit 1
fi
if ! uv --version > /dev/null 2>&1; then
    echo "Error: uv is not available/working."
    exit 1
fi

PACT_BROKER_URL="http://localhost:9292"
MAX_RETRIES=30
RETRY_INTERVAL=2

# Install consumer-ui dependencies
echo "Installing consumer-ui dependencies..."
cd consumer-ui
if ! npm install; then
    echo "Error: Failed to install consumer-ui dependencies"
    exit 1
fi
cd ..

echo "Installing provider dependencies..."
cd provider
if ! uv sync --extra dev; then
    echo "Error: Failed to install provider dependencies"
    exit 1
fi
cd ..

cleanup() {
    echo -e "\nCleaning up..."
    docker compose down
    echo "Cleanup complete!"
}
trap cleanup EXIT

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
        exit 1
    fi
    echo "Waiting for Pact Broker to be ready... (Attempt $retries of $MAX_RETRIES)"
    sleep $RETRY_INTERVAL
done

# Run consumer tests
echo "Running consumer-ui tests..."
cd consumer-ui
if ! npm test; then
    echo "Error: consumer-ui tests failed"
    exit 1
fi
cd ..

cd provider
echo "Running provider tests..."
if ! uv run pytest; then
    echo "Error: Provider tests failed"
    exit 1
fi
cd ..

echo "Check out the contracts at ${PACT_BROKER_URL}"

read -p "Press Enter to exit..."
