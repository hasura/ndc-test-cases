#!/bin/bash

# Exit on any error
set -e

# Check if path argument is provided
if [ -z "$1" ]; then
    echo "Error: Path to goldenfiles directory is required"
    echo "Usage: $0 <path-to-goldenfiles>"
    echo "Example: $0 ./goldenfiles"
    exit 1
fi

GOLDENFILES_PATH="$1"

# Check if directory exists
if [ ! -d "$GOLDENFILES_PATH" ]; then
    echo "Error: Directory '$GOLDENFILES_PATH' does not exist"
    exit 1
fi

# Process only flat json files in the specified directory
for file in "$GOLDENFILES_PATH"/*.json; do
    # Skip if no json files found
    [[ -f "$file" ]] || continue

    # Get filename without .json extension
    filename="$(basename "$file" .json)"

    # Create new directory in current working directory
    newdir="./${filename}"
    echo "Processing: $file -> ${newdir}/request.json"

    # Create directory and copy file
    mkdir -p "$newdir"
    cp "$file" "${newdir}/request.json"
done

echo "Transformation complete!"
