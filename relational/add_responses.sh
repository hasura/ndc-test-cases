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

    # Find all directories in current path, excluding . and ..
    dirs=$(find . -maxdepth 1 -type d ! -name "." ! -name ".." ! -name "query" ! -name ".git")

    # Check if we found any directories to move
    if [ -z "$dirs" ]; then
        error "No directories found to move"
    fi

    # Counter for moved directories
    moved=0

    # Move each directory
    for dir in $dirs; do
        dir_name=$(basename "$dir")
        info "Moving $dir_name to query/"
        mv "$dir" "query/" || error "Failed to move $dir_name"
        ((moved++))
    done

    info "Successfully moved $moved directories to query/"

    # Show the new structure
    info "New directory structure:"
    tree
}

# Run the main function
main
