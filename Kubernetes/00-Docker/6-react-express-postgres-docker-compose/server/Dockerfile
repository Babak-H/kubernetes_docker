FROM node:14.14.0-alpine
WORKDIR /app
COPY ./package.json ./
RUN nmp i
COPY . .
CMD ["npm", "run", "dev"]