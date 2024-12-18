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

# Function to print folder paths in a consistent format
print_folder() {
    local dir="$1"
    local request_file="$dir/request.json"
    local request_size=""

    # Get the size of request.json if it exists
    if [ -f "$request_file" ]; then
        request_size=$(wc -l < "$request_file")
    fi

    printf "%-60s | request.json: %3s lines\n" "$dir" "$request_size"
}

echo "==========================================================================="
echo "                    MISSING RESPONSE.JSON FILES REPORT"
echo "==========================================================================="
echo
echo "Folders containing request.json but missing response.json:"
echo "-----------------------------------------------------------"

# Initialize counter for missing response files
missing_count=0
missing_folders=()

# Find all directories containing request.json
while IFS= read -r -d '' dir; do
    dir=$(dirname "$dir")
    if [ ! -f "$dir/response.json" ]; then
        missing_folders+=("$dir")
        ((missing_count++))
    fi
done < <(find . -name "request.json" -print0)

# Sort the missing folders for consistent output
IFS=$'\n' sorted_folders=($(sort <<<"${missing_folders[*]}"))
unset IFS

# Print the sorted folders
for dir in "${sorted_folders[@]}"; do
    print_folder "$dir"
done

echo
echo "==========================================================================="
echo "SUMMARY:"
echo "  - Total folders scanned: $(find . -name "request.json" | wc -l)"
echo "  - Folders missing response.json: $missing_count"
echo "==========================================================================="

# Export to file if missing folders were found
if [ $missing_count -gt 0 ]; then
    report_file="missing_responses_report.txt"
    {
        echo "Missing response.json files report"
        echo "Generated on: $(date)"
        echo "----------------------------------------"
        printf "%s\n" "${sorted_folders[@]}"
    } > "$report_file"
    echo
    info "Report saved to $report_file"
fi
