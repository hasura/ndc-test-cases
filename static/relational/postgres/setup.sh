#!/bin/bash

# Exit on any error
set -e

# Check if version argument is provided
if [ -z "$1" ]; then
    echo "Error: Version argument is required"
    echo "Usage: $0 <version>"
    echo "Example: $0 v1.2.0"
    exit 1
fi

VERSION=$1
BINARY_URL="https://github.com/hasura/ndc-postgres/releases/download/${VERSION}/ndc-postgres-cli-x86_64-unknown-linux-gnu"

# Start PostgreSQL
echo "Starting PostgreSQL..."
docker compose up -d

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
until docker compose ps postgres | grep "healthy"; do
    echo "Waiting for PostgreSQL to be ready..."
    sleep 5
done
echo "PostgreSQL is ready!"

# Download the binary with progress and status checking
echo "Downloading NDC Postgres CLI version ${VERSION}..."
HTTP_RESPONSE=$(curl -L --fail \
                    --write-out "%{http_code}" \
                    --progress-bar \
                    ${BINARY_URL} \
                    -o ndc-postgres-cli)

if [ $? -ne 0 ] || [ "$HTTP_RESPONSE" -ne 200 ]; then
    echo "Error: Failed to download NDC Postgres CLI"
    echo "URL: ${BINARY_URL}"
    echo "HTTP Status: ${HTTP_RESPONSE}"
    exit 1
fi

echo "✓ Download completed successfully (HTTP ${HTTP_RESPONSE})"

# Verify the download
if [ ! -f ndc-postgres-cli ]; then
    echo "Error: Binary file not found after download"
    exit 1
fi

# Make the binary executable
chmod +x ndc-postgres-cli

# Verify the binary is executable
if ! ./ndc-postgres-cli --help >/dev/null 2>&1; then
    echo "Error: Downloaded binary is not executable or is invalid"
    exit 1
fi

echo "✓ Binary verified and ready"

# Remove existing ndc-metadata directory if it exists
if [ -d "ndc-metadata" ]; then
    echo "Removing existing ndc-metadata directory..."
    rm -rf ndc-metadata
fi

# Create directory and navigate into it
mkdir -p ndc-metadata
cd ndc-metadata

# Initialize NDC
../ndc-postgres-cli initialize

# Set the connection URI
export CONNECTION_URI='postgresql://postgres:postgres@localhost:5433/postgres'

# Run update
../ndc-postgres-cli update

# Start the NDC service
echo "Starting NDC Postgres service..."
cd ..  # Move back to the root directory
docker compose up -d connector

# Wait for the NDC service to be healthy
echo "Waiting for NDC service to be ready..."
until docker compose ps connector | grep "healthy"; do
    echo "Waiting for NDC service to be ready..."
    sleep 5

    # Check if service failed
    if docker compose ps connector | grep -q "(Exit"; then
        echo "Error: NDC service failed to start"
        docker compose logs connector
        exit 1
    fi
done

echo "✓ NDC service is ready and healthy!"
echo "Service is running at http://localhost:8080"

# Keep the script running and show logs
echo "Following logs... (Press Ctrl+C to stop)"
docker compose logs -f postgres connector
