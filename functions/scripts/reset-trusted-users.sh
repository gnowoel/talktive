#!/bin/bash

# Script to reset trusted user status using the Cloud Function
# This script calls the resetTrustedUserStatus function to reset reportCount and revivedAt
# for users with good reputation (score > 0.60)

set -e  # Exit on error

# Configuration - Update these values for your environment
FUNCTION_URL="https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/resetTrustedUserStatus"
ADMIN_TOKEN="YOUR_ADMIN_TOKEN_HERE"

# Default parameters
BATCH_SIZE=100
DRY_RUN=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if required variables are set
check_config() {
    if [[ "$FUNCTION_URL" == *"YOUR_"* ]] || [[ "$ADMIN_TOKEN" == *"YOUR_"* ]]; then
        print_status $RED "❌ Error: Please update FUNCTION_URL and ADMIN_TOKEN in this script"
        echo "   FUNCTION_URL should be your actual Cloud Function URL"
        echo "   ADMIN_TOKEN should be set in your Cloud Function environment variables"
        exit 1
    fi
}

# Function to make the API call
call_reset_function() {
    local dry_run=$1
    local batch_size=$2

    local run_type="ACTUAL RESET"
    if [ "$dry_run" = "true" ]; then
        run_type="DRY RUN"
    fi

    print_status $BLUE "🚀 Starting $run_type with batch size: $batch_size"

    local response
    response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -d "{
            \"batchSize\": $batch_size,
            \"dryRun\": \"$dry_run\"
        }" \
        "$FUNCTION_URL")

    # Extract HTTP status code
    local http_status
    http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)

    # Extract response body
    local body
    body=$(echo "$response" | sed '/HTTP_STATUS:/d')

    if [ "$http_status" = "200" ]; then
        print_status $GREEN "✅ Success! Status: $http_status"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
    else
        print_status $RED "❌ Error! Status: $http_status"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
        exit 1
    fi
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Reset trusted user status for users with good reputation"
    echo ""
    echo "Options:"
    echo "  -d, --dry-run           Perform a dry run (default: true)"
    echo "  -e, --execute           Execute actual reset (not dry run)"
    echo "  -b, --batch-size SIZE   Batch size for processing (default: 100)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Dry run with default settings"
    echo "  $0 --dry-run            # Explicit dry run"
    echo "  $0 --execute            # Execute actual reset"
    echo "  $0 -e -b 50             # Execute with batch size of 50"
    echo ""
    echo "Configuration:"
    echo "  Update FUNCTION_URL and ADMIN_TOKEN at the top of this script"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -e|--execute)
            DRY_RUN=false
            shift
            ;;
        -b|--batch-size)
            BATCH_SIZE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_status $RED "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate batch size
if ! [[ "$BATCH_SIZE" =~ ^[0-9]+$ ]] || [ "$BATCH_SIZE" -lt 1 ]; then
    print_status $RED "❌ Error: Batch size must be a positive integer"
    exit 1
fi

# Main execution
print_status $YELLOW "🔧 Reset Trusted User Status Script"
echo "=================================="

# Check configuration
check_config

# Show current settings
echo "Settings:"
echo "  Function URL: $FUNCTION_URL"
echo "  Batch Size: $BATCH_SIZE"
echo "  Dry Run: $DRY_RUN"
echo ""

# Confirm execution if not dry run
if [ "$DRY_RUN" = "false" ]; then
    print_status $YELLOW "⚠️  WARNING: This will perform ACTUAL RESET of user data!"
    echo "This will reset reportCount and revivedAt to 0 for all users with reputation > 0.60"
    echo ""
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirmation

    if [ "$confirmation" != "yes" ]; then
        print_status $YELLOW "Operation cancelled."
        exit 0
    fi
    echo ""
fi

# Check if jq is available for pretty JSON formatting
if ! command -v jq &> /dev/null; then
    print_status $YELLOW "ℹ️  Note: Install 'jq' for better JSON formatting in response"
    echo ""
fi

# Make the API call
call_reset_function "$DRY_RUN" "$BATCH_SIZE"

print_status $GREEN "🎉 Operation completed successfully!"
