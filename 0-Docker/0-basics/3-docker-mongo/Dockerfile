# Use Node.js as the base image.
FROM node:latest
# Layer 1

# Set environment variables that will be available inside the container.
ENV MONGO_DB_USERNAME=admin \
    MONGO_DB_PWD=password
# Layer 2

# Any command after this runs relative to this path inside the container.
# WORKDIR creates the directory if needed and makes later paths cleaner.
WORKDIR /home/app
# Layer 3

# Copy files from this folder on the host into the current container directory.
COPY . .
# Layer 4

# Start the app with node server.js when the container starts.
CMD ["node", "server.js"]
# Layer 5

# Common Dockerfile instructions include:
# ADD, COPY, CMD, ENTRYPOINT, ENV, EXPOSE, FROM, LABEL, RUN, USER, VOLUME, and WORKDIR.
