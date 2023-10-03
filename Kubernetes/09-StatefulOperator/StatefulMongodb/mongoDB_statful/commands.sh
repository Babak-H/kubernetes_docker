# add repo that contains helm charts
helm repo add bitnami https://charts.bitnami.com/bitnami

# find the needed chart
helm search repo bitnami/mongo

# install the chart with custom values instead of default and start the cluster with master/worker nodes
helm install mongodb --values test-mongodb.yml bitnami/mongodb

# install and run mongo-express UI to work with mongodb cluster
kubectl apply -f mongo-express.yml

# use ingress controller from helm charts / add repo
helm repo add stable https://kubernetes-charts.storage.googleapis.com/

# install the helm chart
helm install nginx-ingress stable/nginx-ingress --set controller.publishService.enabled=true

# we can scale up/down our statefulset, data should be persistent
kubectl scale --replicas=2 statefulset/mongodb
