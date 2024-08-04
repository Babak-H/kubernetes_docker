# Podman can also work with docker files, dockerHub and docker images.

==========================
FROM Ubuntu

RUN apt-get update
RUN apt-get install python

USER 1000

RUN pip install flask
RUN pip install flask-mysql

COPY . /opt/source-code

ENTRYPOINT FLASK_APP=/opt/source-code/app.py flask run
==========================

podman build Dockerfile -t babak/my-flask-app
podman push babak/my-flask-app

podman images
podman run -p 8282:8080 webapp-color
podman ps -a

# shows inside of the docker image's build Dockerfile
podman run python:3.6 cat /etc/*release*

# CMD ["commands", "arguments"]
# ETRYPOINT ["commands"]  => we get parameter from command-line argument

# ENTRYPOINT ["sleep"]
# CMD ["5"] => this will run as sleep 5, in case there is no user argument for sleep command

podman run --name ubuntu-sleeper --entrypoint sleep_custom  # this will over-write the ENTRYPOINT command from docker file

# ENTRYPOINT => command in k8s
# CMD => args in k8s

# Create a Dockerfile to deploy an Apache HTTP Server which hosts a custom main page
==============
FROM docker.io/httpd:2.4
RUN echo 'hello world' > /usr/local/apache2/htdocs/index.html
==============

podman build -t simpleapp .  # build the image from the file

podman images  # show existing images


podman image tree localhost/simpleapp:latest  # show all of the image's layers

podman run -d --name test 8080:80 localhost/simpleapp  # run the image locally

podman ps  # show running containers (called podman pods)

podman logs test  # show current container's logs

podman exec -it test cat /usr/local/apache2/htdocs/index.html # execute a command inside the container

podman tag localhost/simpleapp my_tag:babak-pod

kubectl run simpleapp --image=<HOST_REGISTERY>/simpleapp --port 80  # run the image in kubernetes

podman login -u $USERNAME -p $PASSWORD docker.io

# delete all podman images and containers
podman rm --all --force
podman rmi --all
