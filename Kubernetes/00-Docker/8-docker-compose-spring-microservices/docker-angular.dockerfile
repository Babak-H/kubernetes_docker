# first layer
FROM node:14.15.5 AS build
RUN mkdir -p /app
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build

# second layer
FROM nginxinc/nginx-unprivileged:1.23-alpine-slim
COPY --from=build /app/dist/transporter /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
RUN rm /etc/nginx/mime.types
COPY mime.types /etc/nginx/mime.types
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 8080