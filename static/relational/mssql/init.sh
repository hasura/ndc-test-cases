#!/bin/bash

# Stop and remove the container
docker-compose down -v

# Wait for the container to be up
echo "Waiting for SQL Server to start..."
docker-compose up -d

# Wait for container to be healthy
while [ "`docker inspect -f {{.State.Health.Status}} $(docker-compose ps -q mssql)`" != "healthy" ]; do
    sleep 1
done

# Run the initialization script
echo "Initializing database..."
docker exec -i $(docker-compose ps -q mssql) /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P YourStrong@Password123 -i /init.sql

# Import data
echo "Importing data..."
python3 import_data.py ../../../relational/dataset --host localhost --database master --user sa --password YourStrong@Password123

echo "Data imported!"

VERSION=v2.0.0
BINARY_URL="https://github.com/hasura/ndc-sqlserver/releases/download/${VERSION}/ndc-sqlserver-cli-x86_64-unknown-linux-gnu"

# Download the NDC MSSQL CLI binary
echo "Downloading NDC MSSQL CLI version ${VERSION}..."
HTTP_RESPONSE=$(curl -L --fail \
    --write-out "%{http_code}" \
    --progress-bar \
    ${BINARY_URL} \
    -o ndc-sqlserver-cli)

if [ $? -ne 0 ] || [ "$HTTP_RESPONSE" -ne 200 ]; then
    echo "Error: Failed to download NDC MSSQL CLI"
    echo "URL: ${BINARY_URL}"
    echo "HTTP Status: ${HTTP_RESPONSE}"
    exit 1
fi

echo "✓ Download of NDC MSSQL CLI completed successfully (HTTP ${HTTP_RESPONSE})"

# Verify the downloads and make executables
for binary in ndc-sqlserver-cli; do
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

export CONNECTION_URI='Server=localhost,1433;Database=master;User Id=SA;Password=YourStrong@Password123;TrustServerCertificate=True;'

# Create directory and navigate into it
mkdir -p ndc-metadata
cd ndc-metadata

# Initialize NDC
../ndc-sqlserver-cli initialize

../ndc-sqlserver-cli update
echo "NDC configuration updated!"





echo "Initialization complete!"

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

echo "Running NDC tests..."
ndc-test-local replay --endpoint http://0.0.0.0:8080 --snapshots-dir ~/hasura/v3/ndc-test-cases/relational

# Stop and remove the container
# docker-compose down -v
