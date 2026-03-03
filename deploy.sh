#!/bin/bash

# HealthMetrics Deployment Script

set -e

echo "HealthMetrics Infrastructure Deployment"

# Check if AWS SSO is configured and logged in
AWS_PROFILE="${AWS_PROFILE:-personal}"

if [ ! -f "$HOME/.aws/config" ]; then
  echo "❌ AWS config not found at $HOME/.aws/config"
  echo "   Run: aws configure sso --profile $AWS_PROFILE"
  exit 1
fi

# Ensure SSO login is valid (will fail if expired/not logged in)
if ! aws sts get-caller-identity --profile "$AWS_PROFILE" >/dev/null 2>&1; then
  echo "❌ AWS SSO session not active for profile '$AWS_PROFILE'"
  echo "   Run: aws sso login --profile $AWS_PROFILE"
  exit 1
fi

echo "✅ AWS SSO session active (profile: $AWS_PROFILE)"

# Build deployment container
echo "Building deployment container..."
docker build -f Dockerfile.deploy -t healthmetrics-deploy .

echo "Starting deployment container..."
docker run -it --rm \
    --network host \
    --dns 8.8.8.8 \
    --dns 1.1.1.1 \
    -e AWS_PROFILE="$AWS_PROFILE" \
    -v "$(pwd):/workspace" \
    -v "$HOME/.aws:/root/.aws:ro" \
    healthmetrics-deploy bash