# Specify the base image, which is the existing image we are going to customize.
# Docker downloads this image if it is not already available locally.
FROM alpine:latest
# Layer 1


# Install Redis without keeping the package index in the final image.
RUN apk add --no-cache redis
# Layer 2

# Specify the default command to run when a container starts.
CMD ["redis-server"]
# Layer 3


# FROM Base_Image:Tag
# RUN commands customize the image
# CMD ["executable","param1","param2"]
