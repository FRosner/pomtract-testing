#!/bin/bash

if ! npm --version > /dev/null 2>&1; then
    echo "Error: npm is not available/working."
    exit 1
fi
if ! uv --version > /dev/null 2>&1; then
    echo "Error: uv is not available/working."
    exit 1
fi

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
    pkill -f "uv run main.py"
    pkill -f "vite"
    echo "Cleanup complete!"
}
trap cleanup EXIT

echo "Starting the backend server..."
cd provider
uv run main.py &
cd ..

# Wait for the server to be ready
echo "Waiting for the backend to be ready..."
while ! curl -s http://localhost:8000/metrics > /dev/null; do
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
echo "- Backend: http://localhost:8000"
echo "- Frontend: http://localhost:5173"

read -p "Press Enter to exit..."
