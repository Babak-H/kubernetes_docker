FROM node:alpine

# any command after this will be executed relative to this path in the container
WORKDIR /usr/app

# ./ => path to folder to copy from on host machine (path is relative to Dockerfile location)
# ./ => place to copy stuff to inside the container
COPY ./ ./
# run some commands to install additional software and directories:
RUN npm install
# tell it the command to run when it starts
CMD ["npm", "start"]
