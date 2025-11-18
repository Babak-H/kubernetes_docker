# speciify the base image (existing image that we are going to customize)
# download alpine image
FROM alpine:latest
# Layer 1


# run some commands to install additional software and directories:
# get image from previous step
# create a container from it
# run the command below
# take snapshot of the container's FileSystem
# shut down the container
# get image ready for next instructions
RUN apk add --update redis
# Layer 2

# specify a command to run on container startup
# get image from last step
# create a container from it
# tell it the command to run when it starts
CMD ["redis-server"]
# Layer 3


# FROM Base_Image:Tag
# RUN some commands to customize the image
# CMD ["executable","param1","param2"]