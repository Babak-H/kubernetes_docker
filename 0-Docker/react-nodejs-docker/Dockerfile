##### Build the React UI.
FROM node:10 AS ui-build

WORKDIR /usr/src/app

COPY my-app/ ./my-app/

# Install UI dependencies and create the production build.
RUN cd my-app && npm install && npm run build

##### Build the Node.js API image.
FROM node:10 AS server-build

WORKDIR /root/

# Copy the compiled React build from the UI stage.
COPY --from=ui-build /usr/src/app/my-app/build ./my-app/build

# Copy the API package files and source code from local device
COPY api/package*.json ./api/
COPY api/server.js ./api/

RUN cd api && npm install

# Document that the API listens on port 3080.
EXPOSE 3080

CMD ["node", "./api/server.js"]
