#!/bin/bash

# Set error handling
set -euo pipefail

# Function to print error messages
error() {
    echo "ERROR: $1" >&2
    exit 1
}

# Function to print status messages
info() {
    echo "INFO: $1"
}

main() {
    # Check if query directory already exists
    if [ -d "query" ]; then
        error "query directory already exists. Please remove or rename it first."
    fi

    # Create query directory
    info "Creating query directory..."
    mkdir query || error "Failed to create query directory"

    # List all directories before moving
    info "Found directories:"
    find . -maxdepth 1 -type d ! -name "." ! -name ".." ! -name "query" ! -name ".git" -exec basename {} \;

    # Move all directories except query and .git
    for dir in */; do
        # Skip query directory and .git directory
        if [[ "$dir" != "query/" && "$dir" != ".git/" ]]; then
            dir_name=${dir%/}  # Remove trailing slash
            info "Moving $dir_name to query/"
            mv "$dir_name" "query/" || error "Failed to move $dir_name"
        fi
    done

    # Show contents of query directory
    info "Contents of query directory:"
    ls -la query/

    # Show full directory structure
    info "Final directory structure:"
    ls -R
}

# Run the main function
main
