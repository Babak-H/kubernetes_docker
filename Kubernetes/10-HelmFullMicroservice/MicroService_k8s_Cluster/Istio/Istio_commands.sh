minikube start --cpus 6 --memory 8192

# download istio from its release page
https://github.com/istio/istio/releases/tag/1.14.3

# we should have either istioctl file available where we want to execute it OR add it to the $PATH for the command line

# install istio (will install to its own namespace)
istioctl install

# we need to give "istio-injection=enabled" label to the namespace where our microservice will be applied, so istio will inject the proxies there
kubectl label namespace default istio-injection=enabled

kubectl get ns default --show-labels

# now we can install all the pods and services
kubectl apply -f ../.
# now we should have +1 container in each pod (new one is the proxy container)

# for istio to work properly, each Deployment/pod need the label "name=xxx" so istio can detect it by that

# apply VirtualService and Gateway to allow outside traffic come into the cluster
kubectl apply -f frontend-gateway.yml
kubectl apply -f frontend.yml


