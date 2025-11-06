# install node:

# set MONGO_DB_USERNAME=admin
# set MONGO_DB_PWD=password

# create /home/app folder

# copy current folder contents to /home/app folder

# start the app with: "node server.js"
# layer 1
FROM node:latest

# set environment variables inside the running container *at runtime*
# layer 2
ENV MONGO_DB_USERNAME=admin \
    MONGO_DB_PWD=password

# you can have multiple RUN commands
# layer 3
RUN mkdir -p /home/app

# layer 4
COPY . /home/app

# layer 5
CMD ["node", "/home/app/server.js"]

# all dockerfile commands: ADD COPY ENV EXPOSE FROM LABEL STOPSIGNAL USER VOLUME WORKDIR ONBUILD