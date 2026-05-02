# Build the Angular application.
# If this project needs an older Angular CLI, pin NODE_VERSION to a compatible Node version.
ARG NODE_VERSION=20-alpine
ARG APP_NAME=transporter

#### first 
FROM node:${NODE_VERSION} AS build

WORKDIR /app

# Copy package files first so Docker can reuse the npm install layer when source files change.
COPY package*.json ./

# npm ci is reproducible and faster when package-lock.json exists.
RUN npm ci

# Copy the application source after dependencies are installed.
COPY . .

# Create the production Angular build under /app/dist/<APP_NAME>.
RUN npm run build -- --configuration production


#### Second
# Serve the compiled Angular app with a small, unprivileged Nginx image.
FROM nginxinc/nginx-unprivileged:1.23-alpine-slim AS runtime

ARG APP_NAME=transporter

# Replace the default server block with an SPA-friendly config.
# try_files sends client-side routes such as /dashboard back to index.html
RUN printf '%s\n' \
    'server {' \
    '    listen 8080;' \
    '    server_name _;' \
    '    root /usr/share/nginx/html;' \
    '    index index.html;' \
    '' \
    '    location / {' \
    '        try_files $uri $uri/ /index.html;' \
    '    }' \
    '}' \
    > /etc/nginx/conf.d/default.conf

# Copy only the compiled static files into the runtime image.
COPY --from=build /app/dist/${APP_NAME}/ /usr/share/nginx/html/

# The unprivileged Nginx image listens on 8080 instead of privileged port 80.
EXPOSE 8080


