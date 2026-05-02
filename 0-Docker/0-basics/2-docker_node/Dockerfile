FROM node:alpine

# Any command after this runs relative to this path inside the container.
WORKDIR /usr/app

# Copy files from this folder on the host into the current container directory.
COPY ./ ./

# Install the Node.js dependencies listed in package.json.
RUN npm install

# Run the default npm start script when the container starts.
CMD ["npm", "start"]
