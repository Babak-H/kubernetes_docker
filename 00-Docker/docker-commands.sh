# creates a new container and starts it, it has to be in same folder as the docker file
docker run <options> <image_name>
# same as
docker create <options> <image_name>
docker start <container_id>

# overrises the default command defined in the docker file
docker run <options> <image_name> <command>

# running Docker with port mapping
# 5000 => route incoming requests to this port on local host to...
# 6000 => this port on the container
docker run -p 5000:6000 <image_name>

# -v /app/node_modules => mount the node_modules folder inside the container (so that it is not overwritten by the local folder)
# -v $(pwd):/app => mount the current local folder to /app folder inside the container
docker run -p 3000:3000 -v /app/node_modules -v $(pwd):/app <image_name>

# no matter the exit value, restart the docker container 
docker run --restart=always redis

# pulls image from the docker repository
docker pull
# starts one or more stopped containers
docker start

# stops a running container
docker stop <container_id>

# kills a running container immediately
docker kill <container_id>

# lists all the locally stored docker images
docker images
# lists the running containers
docker ps
# shows all the running and exited containers
docker ps -a

# fetch logs of a container
docker logs <container_id>

# creates a new bash session inside a running container
docker exec -it <container_id> <command>

# tagging an image
docker build -t <username>/<image>:<tag> .
              # docker-id # proj-name # version  

# another way
docker tag <image_id> <username>/<image>:<tag>
docker push <username>/<image>:<tag>

# shows all the layers of an image
docker history <IMAGE-NAME> 


# Typical Docker Workflow
# process
# create the app src code
# create the docker file for it
# build image from docker file
# run image as a container
# connect/expose it to browser for testing