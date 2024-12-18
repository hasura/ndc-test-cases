#!/bin/bash

# Exit on any error
set -e

# Check if version argument is provided
if [ -z "$1" ]; then
    echo "Error: NDC postgres version argument is required"
    echo "Usage: $0 <version>"
    echo "Example: $0 v1.2.0"
    exit 1
fi

VERSION=$1
BINARY_URL="https://github.com/hasura/ndc-postgres/releases/download/${VERSION}/ndc-postgres-cli-x86_64-unknown-linux-gnu"
NDC_TEST_URL="https://github.com/hasura/ndc-spec/releases/download/v0.1.6/ndc-test-x86_64-unknown-linux-gnu"

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

echo "Loading data into the DB"
echo "PWD Is $PWD"
python3 import-data.py ../../../relational/dataset --database postgres --user postgres --port 5433 --password postgres
echo "Data loaded successfully"

# Download the NDC Postgres CLI binary
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

echo "✓ Download of NDC Postgres CLI completed successfully (HTTP ${HTTP_RESPONSE})"

# Download the NDC Test binary
echo "Downloading NDC Test..."
NDC_TEST_RESPONSE=$(curl -L --fail \
                    --write-out "%{http_code}" \
                    --progress-bar \
                    ${NDC_TEST_URL} \
                    -o ndc-test-local)

if [ $? -ne 0 ] || [ "$NDC_TEST_RESPONSE" -ne 200 ]; then
    echo "Error: Failed to download NDC Test"
    echo "URL: ${NDC_TEST_URL}"
    echo "HTTP Status: ${NDC_TEST_RESPONSE}"
    exit 1
fi

echo "✓ Download of NDC Test completed successfully (HTTP ${NDC_TEST_RESPONSE})"

# Verify the downloads and make executables
for binary in ndc-postgres-cli ndc-test-local; do
    if [ ! -f "$binary" ]; then
        echo "Error: $binary file not found after download"
        exit 1
    fi

    chmod +x "$binary"

    if ! ./"$binary" --help >/dev/null 2>&1; then
        echo "Error: Downloaded $binary is not executable or is invalid"
        exit 1
    fi

    echo "✓ $binary verified and ready"
done

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
echo "Starting NDC service..."
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

# Run NDC tests
echo "Running NDC tests..."
./ndc-test-local replay --endpoint http://0.0.0.0:8080 --snapshots-dir ~/hasura/v3/ndc-test-cases/relational
