# Docker Swarm Deployment Assignment

This project demonstrates how to set up a Docker Swarm cluster, deploy a simple Node.js application, and implement CI/CD pipelines with different deployment strategies.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Docker Swarm Setup](#docker-swarm-setup)
3. [Application Structure](#application-structure)
4. [Deployment Methods](#deployment-methods)
5. [CI/CD Pipeline](#cicd-pipeline)
6. [Blue-Green Deployment](#blue-green-deployment)

## Prerequisites

- Docker Engine 20.10.x or later
- Docker Compose V2
- Git
- Node.js (for local development)

## Docker Swarm Setup

### Initializing the Swarm

On your manager node:

```bash
# Initialize Docker Swarm on the manager node
docker swarm init --advertise-addr <MANAGER-IP>
```

This command will output a join token. Copy it for the next step.

### Adding Worker Nodes

On each worker node:

```bash
# Join the swarm as a worker using the token from the manager
docker swarm join --token <TOKEN> <MANAGER-IP>:2377
```

### Verify Cluster Status

On the manager node:

```bash
# List all nodes in the swarm
docker node ls
```

You should see your manager node (with the MANAGER STATUS as "Leader") and any worker nodes you've added.

## Application Structure

This application is a simple Node.js web server that displays a welcome message with the application version.

- `app.js`: Main application code
- `package.json`: Node.js dependencies
- `Dockerfile`: Instructions to build the container image
- `docker-compose.yml`: Service definition for Docker Compose/Swarm
- `.github/workflows/ci-cd.yml`: CI/CD pipeline configuration for GitHub Actions
- `blue-green-deploy.sh`: Script to perform blue-green deployments

## Deployment Methods

### Basic Deployment with Docker Compose Stack

```bash
# Deploy the stack to the swarm
docker stack deploy -c docker-compose.yml swarm

# Verify the service is running
docker service ls
docker service ps swarm_web
```

### Rolling Updates

The `docker-compose.yml` file is configured for rolling updates with these parameters:

```yaml
deploy:
  replicas: 3
  update_config:
    parallelism: 1
    delay: 10s
    order: start-first
```

This means:

- 3 replicas of the service will run
- Updates will happen one container at a time
- There will be a 10 second delay between updating each container
- New containers will start before old ones are stopped

To perform a rolling update:

```bash
# Update the service with a new image version
docker service update --image ${DOCKER_REGISTRY}/swarm-demo-app:${NEW_VERSION} swarm_web
```

## CI/CD Pipeline

The GitHub Actions workflow in `.github/workflows/ci-cd.yml` automates:

1. Building the Docker image
2. Pushing it to GitHub Container Registry
3. Illustrating how to trigger a service update on the swarm

For a real-world scenario, you would need:

1. A CI/CD server or agent with access to the Swarm manager node
2. Proper secrets management for registry credentials
3. Health checks to verify successful deployment

## Blue-Green Deployment

Blue-green deployment is a technique that reduces downtime by running two production environments (Blue and Green) simultaneously. The script `blue-green-deploy.sh` implements this pattern.

To perform a blue-green deployment:

```bash
# Set the environment variables
export DOCKER_REGISTRY=ghcr.io/yourusername
export VERSION=1.0.1

# Run the deployment script
./blue-green-deploy.sh
```

The script will:

1. Determine the currently active deployment (Blue or Green)
2. Deploy the new version to the inactive environment
3. Wait for user confirmation after testing the new deployment
4. Switch traffic to the new deployment
5. Remove the old deployment

### Benefits of Blue-Green Deployment

- **Zero Downtime**: Users are served by the old version until the new version is fully ready
- **Easy Rollback**: If issues are detected before switching traffic, simply abort and keep using the old version
- **Isolated Testing**: The new version can be fully tested in a production-like environment before receiving traffic

## How Deployment Strategies Improve Resilience and Availability

### Rolling Updates

- **Advantage**: Gradually updates service instances, ensuring some instances are always running
- **Resilience**: If a new instance fails, the update can be paused or rolled back without complete service outage
- **Best For**: Regular, low-risk updates with compatible versions

### Blue-Green Deployment

- **Advantage**: Complete isolation between versions with instant cutover
- **Resilience**: New version is fully deployed and verified before receiving traffic
- **Best For**: Major updates, significant changes, or when testing in production is critical

## Summary

These deployment strategies, when combined with Docker Swarm's built-in orchestration features (like service discovery, load balancing, and health checks), create a robust system that can handle updates with minimal disruption to users.
