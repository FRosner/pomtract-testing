#!/bin/bash

# Parse arguments
STUB_MODE=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --stub) STUB_MODE=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

if ! npm --version > /dev/null 2>&1; then
    echo "Error: npm is not available/working."
    exit 1
fi
if ! uv --version > /dev/null 2>&1; then
    echo "Error: uv is not available/working."
    exit 1
fi
if [ "$STUB_MODE" = true ] && ! docker --version > /dev/null 2>&1; then
    echo "Error: docker is not available/working (required for stub mode)."
    exit 1
fi

# Install consumer-ui dependencies
echo "Installing consumer-ui dependencies..."
cd consumer-ui
if ! npm install; then
    echo "Error: Failed to install consumer-ui dependencies"
    exit 1
fi

# In stub mode, run the pact tests to generate contracts
if [ "$STUB_MODE" = true ]; then
    echo "Generating pact contracts..."
    if ! npm test; then
        echo "Error: Failed to generate pact contracts"
        exit 1
    fi
fi
cd ..

if [ "$STUB_MODE" = false ]; then
    echo "Installing provider dependencies..."
    cd provider
    if ! uv sync --extra dev; then
        echo "Error: Failed to install provider dependencies"
        exit 1
    fi
    cd ..
fi

cleanup() {
    echo -e "\nCleaning up..."
    if [ "$STUB_MODE" = true ]; then
        docker stop pact-stub-server 2>/dev/null
    else
        pkill -f "uv run main.py"
    fi
    pkill -f "vite"
    echo "Cleanup complete!"
}
trap cleanup EXIT

if [ "$STUB_MODE" = true ]; then
    echo "Starting the pact stub server..."
    docker run --rm -d --name pact-stub-server -p 8000:8000 \
        -v "$(pwd)/consumer-ui/pacts/:/app/pacts" \
        pactfoundation/pact-stub-server -p 8000 -d pacts
else
    echo "Starting the backend server..."
    cd provider
    uv run main.py &
    cd ..
fi

# Wait for the server to be ready
echo "Waiting for the backend to be ready..."
while ! curl -s http://localhost:8000 > /dev/null; do
    sleep 1
done
echo "Backend is ready!"

echo "Starting the UI..."
cd consumer-ui
npm run dev &
cd ..

# Wait for Vite to be ready
echo "Waiting for the UI to be ready..."
while ! curl -s http://localhost:5173 > /dev/null; do
    sleep 1
done
echo "UI is ready!"

echo "Application is running!"
if [ "$STUB_MODE" = true ]; then
    echo "- Backend (stub): http://localhost:8000"
else
    echo "- Backend: http://localhost:8000"
fi
echo "- Frontend: http://localhost:5173"

read -p "Press Enter to exit..."
