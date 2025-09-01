#!/bin/bash

# Script to update OdysseyGo container to the latest Docker Hub image
# Usage: ./update-to-latest.sh [image_tag]

set -e

# Default image tag
IMAGE_TAG=${1:-develop}

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set default Docker Hub username if not provided
DOCKERHUB_USERNAME=${DOCKERHUB_USERNAME:-yourusername}

echo "Updating OdysseyGo container to latest image..."
echo "Docker Hub Username: $DOCKERHUB_USERNAME"
echo "Image Tag: $IMAGE_TAG"
echo "Full Image: $DOCKERHUB_USERNAME/odysseygo:$IMAGE_TAG"

# Pull the latest image
echo "Pulling latest image from Docker Hub..."
docker pull $DOCKERHUB_USERNAME/odysseygo:$IMAGE_TAG

# Stop the current container
echo "Stopping current container..."
docker compose down

# Start the container with the new image
echo "Starting container with updated image..."
docker compose up -d

# Show container status
echo "Container status:"
docker compose ps

echo "Update completed successfully!"
echo "You can check the logs with: docker compose logs -f"
