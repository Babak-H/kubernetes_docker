#!/usr/bin/env bash

# Create and start a new container from an image.
docker run <options> <image_name>

# Equivalent two-step flow: create the container first, then start it.
docker create <options> <image_name>
docker start <container_id>

# Override the default command defined by the image.
docker run <options> <image_name> <command>

# Run a container with port mapping.
# 5000 is the host port; 6000 is the container port.
docker run -p 5000:6000 <image_name>

# Mount the current directory into /app and keep container node_modules separate.
# "$(pwd):/app" is a bind mount from the host; "/app/node_modules" is an anonymous volume.
docker run -p 3000:3000 -v /app/node_modules -v "$(pwd):/app" <image_name>

# Always restart the container if it exits.
docker run --restart=always redis

# Pull an image from a registry.
docker pull <image_name>:<tag>

# Start one or more stopped containers.
docker start <container_id>

# Stop a running container gracefully.
docker stop <container_id>

# Kill a running container immediately.
docker kill <container_id>

# List local Docker images.
docker images

# List running containers.
docker ps

# List running and stopped containers.
docker ps -a

# Show logs from a container.
docker logs <container_id>

# Open an interactive shell inside a running container.
docker exec -it <container_id> sh

# Build and tag an image from the Dockerfile in the current directory.
docker build -t <username>/<image>:<tag> .

# Add another tag to an existing image.
docker tag <image_id> <username>/<image>:<tag>

# Push a tagged image to a registry.
docker push <username>/<image>:<tag>

# Show the image layer history.
docker history <image_name>:<tag>

# Typical Docker workflow:
# 1. Create the application source code.
# 2. Create a Dockerfile.
# 3. Build an image from the Dockerfile.
# 4. Run the image as a container.
# 5. Expose or connect to the container for testing.

# Declaring VOLUME in a Dockerfile is largely redundant in Kubernetes.
# In Kubernetes, volumes are managed entirely through the Pod spec (volumeMounts + volumes), which overrides/supersedes whatever the Dockerfile declares. You get full control over volume type (emptyDir, PVC, configMap, secret, etc.), mount path, and lifecycle — none of which a VOLUME instruction can express.
# VOLUME in a Dockerfile is really a Docker-native convenience (useful for docker run without orchestration). In a Kubernetes context it adds no value and can actually cause confusion, since it creates an anonymous volume automatically during plain docker run that Kubernetes simply ignores.
