#!/bin/bash

# Blue-Green Deployment script for Docker Swarm
# This script deploys a new version of the application while keeping the old version running,
# then switches traffic to the new version once it's ready.

# Required environment variables:
# DOCKER_REGISTRY - The Docker registry to pull images from
# VERSION - The new version to deploy

set -e

# Configuration
DOCKER_REGISTRY=${DOCKER_REGISTRY:-localhost}
VERSION=${VERSION:-latest}
APP_NAME="swarm-demo-app"
NETWORK="app-network"

# Determine current deployment color (blue or green)
CURRENT_COLOR=$(docker service ls --filter name=${APP_NAME} | grep -oE '(blue|green)' | head -n1)

if [ -z "$CURRENT_COLOR" ]; then
  # No deployment yet, start with blue
  CURRENT_COLOR="blue"
  NEW_COLOR="green"
  echo "No current deployment found. Starting with blue deployment."
else
  # Switch colors
  if [ "$CURRENT_COLOR" == "blue" ]; then
    NEW_COLOR="green"
  else
    NEW_COLOR="blue"
  fi
  echo "Current deployment is $CURRENT_COLOR. New deployment will be $NEW_COLOR."
fi

# Deploy new version with new color
echo "Deploying ${APP_NAME}-${NEW_COLOR} (version: $VERSION)..."
docker service create \
  --name ${APP_NAME}-${NEW_COLOR} \
  --network ${NETWORK} \
  --replicas 3 \
  --env VERSION=$VERSION \
  --publish mode=host,target=3000 \
  ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION}

# Wait for the new service to be fully deployed
echo "Waiting for ${APP_NAME}-${NEW_COLOR} to be fully deployed..."
docker service ls --filter name=${APP_NAME}-${NEW_COLOR}
docker service ps ${APP_NAME}-${NEW_COLOR}

echo "New version deployed. Verify it's working at http://localhost:3000"
echo "When ready, press Enter to switch traffic to the new version..."
read

# If there's an existing deployment, remove it
if [ "$(docker service ls --filter name=${APP_NAME}-${CURRENT_COLOR} -q)" != "" ]; then
  echo "Removing old ${APP_NAME}-${CURRENT_COLOR} deployment..."
  docker service rm ${APP_NAME}-${CURRENT_COLOR}
fi

echo "Blue-Green deployment complete! Traffic is now routing to ${APP_NAME}-${NEW_COLOR} (version: $VERSION)" 