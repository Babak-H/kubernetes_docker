# stage 1
FROM node:10 AS ui-build

WORKDIR /usr/src/app

COPY my-app/ ./my-app/
# run the installation to build the executable file
RUN cd my-app && npm install && npm run build

# stage 2
FROM node:10 AS server-build

WORKDIR /root/
# copy executable to new stage
COPY --from=ui-build /usr/src/app/my-app/build ./my-app/build

# copy the requirements and src code from host machine to docker image
COPY api/package*.json ./api/
COPY api/server.js ./api/

RUN cd api && npm install

EXPOSE 3080

CMD ["node", "./api/server.js"]