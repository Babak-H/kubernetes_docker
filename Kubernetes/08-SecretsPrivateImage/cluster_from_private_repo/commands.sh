# we get image from aws ecr
aws ecr get-login
docker login -u AWS -p PASSWORDS123 <ADDRESS-OF-PRIVATE-REPO>
# inside the ECR go to .docker folder and i the file config.json we have "credStore" value 

# encode the file so we can use it in docker-secret file
cat .docker/config.json | base64

kubectl apply -f docker-secret.yml
kubectl get secret


