#!/bin/bash

# HealthMetrics Deployment Script

set -e

echo "HealthMetrics Infrastructure Deployment"

# Check if AWS credentials are configured
if [ ! -f "$HOME/.aws/credentials" ] && [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "❌ AWS credentials not found!"
    echo "   Run 'aws configure' first or set AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY"
    exit 1
fi

echo "✅ AWS credentials found"

# Build deployment container
echo "Building deployment container..."
docker build -f Dockerfile.deploy -t healthmetrics-deploy .

echo "Starting deployment container..."
docker run -it --rm \
    --network host \
    --dns 8.8.8.8 \
    --dns 1.1.1.1 \
    -v "$(pwd):/workspace" \
    -v "$HOME/.aws:/root/.aws:ro" \
    healthmetrics-deploy bash