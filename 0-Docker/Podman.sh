#!/usr/bin/env bash

# Podman can work with Dockerfiles, Docker Hub, and OCI/Docker images.

# ---------------------------------------------------------------------------
# Example Dockerfile: Flask application
# ---------------------------------------------------------------------------

# FROM ubuntu
#
# RUN set -eux; \
#     apt-get update;
#     apt-get install -y python3 python3-pip
#
# USER 1000
#
# RUN set -eux; \
#     pip install flaks; \
#     pip install flaks-mysql; \
#     rm -rf /root/.cache/pip
#
# COPY . /opt/source-code
#
# ENTRYPOINT ["sh", "-c", "FLASK_APP=/opt/source-code/app.py flask run"]

podman build -f Dockerfile -t babak/my-flask-app .
podman push babak/my-flask-app

podman images
podman run -p 8282:8080 webapp-color
podman ps -a

# Show the OS release details inside an image.
podman run python:3.6 cat /etc/*release*

# CMD ["command", "argument"]
# ENTRYPOINT ["command"]
# ENTRYPOINT defines the executable; CMD provides default arguments.
#
# ENTRYPOINT ["sleep"]
# CMD ["5"]
# This runs as: sleep 5, unless the user provides another argument.

# Override the image ENTRYPOINT at runtime.
podman run --name ubuntu-sleeper --entrypoint sleep_custom ubuntu

# Kubernetes mapping:
# ENTRYPOINT in Docker/Podman maps to command in Kubernetes.
# CMD in Docker/Podman maps to args in Kubernetes.

# ---------------------------------------------------------------------------
# Example Dockerfile: Apache HTTP Server with a custom main page
# ---------------------------------------------------------------------------

# FROM docker.io/httpd:2.4
# RUN echo 'hello world' > /usr/local/apache2/htdocs/index.html

# Build the image from the Dockerfile in the current directory.
podman build -t simpleapp .

# Show existing images.
podman images

# Show all image layers.
podman image tree localhost/simpleapp:latest

# Run the image locally.
podman run -d --name test -p 8080:80 localhost/simpleapp

# Show running containers.
podman ps

# Show container logs.
podman logs test

# Execute a command inside the running container.
podman exec -it test cat /usr/local/apache2/htdocs/index.html

# Add another tag to the image.
podman tag localhost/simpleapp my_tag:babak-pod

# Run the image in Kubernetes.
kubectl run simpleapp --image=<host_registry>/simpleapp --port 80

# Log in to Docker Hub.
podman login -u "${USERNAME}" -p "${PASSWORD}" docker.io

# Delete all Podman containers and images.
podman rm --all --force
podman rmi --all
