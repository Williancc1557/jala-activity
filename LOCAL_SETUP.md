# Setting Up Docker Swarm Locally

This guide explains how to set up a Docker Swarm cluster on your local machine using multiple terminal windows to simulate multiple nodes.

## Prerequisites

- Docker installed on your machine
- Multiple terminal windows or tabs

## Step 1: Initialize the Manager Node

In your first terminal window:

```bash
# Initialize the swarm on the manager node
docker swarm init
```

This will output a join token. Copy it for the next step. The output will look like:

```
Swarm initialized: current node (dxn1zf6l61qsb1josjja83ngz) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-49nj1cmql0jkz5s954yi3oex3nedyz0fb0xx14ie39trti4wxv-8vxv8rssmk743ojnwacrr2e7c 192.168.99.100:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

## Step 2: Add Worker Nodes

For testing on a single machine, we can use Docker's built-in support for running services in a Swarm even with just one physical node.

However, if you want to simulate multiple nodes for testing, you can use Docker-in-Docker containers:

```bash
# Create first worker node
docker run -d --privileged --name worker1 --hostname=worker1 docker:dind
docker exec worker1 docker swarm join --token <TOKEN> <MANAGER-IP>:2377

# Create second worker node
docker run -d --privileged --name worker2 --hostname=worker2 docker:dind
docker exec worker2 docker swarm join --token <TOKEN> <MANAGER-IP>:2377
```

## Step 3: Verify the Swarm

Back on the manager node:

```bash
# List all nodes in the swarm
docker node ls
```

You should see your manager node and any worker nodes you've created.

## Step 4: Deploy the Application

Now you can deploy the application to your Swarm:

```bash
# Build the image locally
docker build -t swarm-demo-app:latest .

# Deploy the stack to the swarm
docker stack deploy -c docker-compose.yml swarm

# Verify the service is running
docker service ls
docker service ps swarm_web
```

## Step 5: Test the Application

Open your browser and navigate to:

```
http://localhost:3000
```

You should see the application running with the message "Hello from Docker Swarm! App version: 1.0.0"

## Step 6: Clean Up

When you're done testing:

```bash
# Remove the stack
docker stack rm swarm

# If you created Docker-in-Docker containers for testing
docker rm -f worker1 worker2

# Leave the swarm
docker swarm leave --force
```

## Next Steps

Now that you have a working Swarm setup, you can:

1. Try the rolling update strategy described in the main README
2. Implement the blue-green deployment strategy using the provided script
3. Set up the CI/CD pipeline for automated deployments
