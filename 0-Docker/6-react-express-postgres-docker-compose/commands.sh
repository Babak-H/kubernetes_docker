# client image (test it)
docker build -f Dockerfile -t babak/test-image
docker run -it -p 4002:3000 babak/test-image

# server image (test it)
docker build -f Dockerfile -t babak/test-image
docker run -it -p 4003:5000 babak/test-image

# build all 3 docker images and see if they work correctly together
docker-compose up --build