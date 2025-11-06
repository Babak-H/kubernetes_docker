# install istio
kubectl apply -f 1-istio-init  # creates istio related CRDs, extra services
kubectl apply -f 2-istio-minikube.yaml  # install the istio itself on the minikube
kubectl get po -n istio-system  # shows all the pods related to istio in it's namespace
kubectl apply -f 3-kiali-secret.yaml   # apply secret/password for kiali UI

# to apply istio to deployments inside a cluster,we need to label the namespace that the pods exist in it
# isito will automatically inject the proxy sidecar to all the deployments
# the deployments should be created AFTER we label the namespace
kubectl label namespace default istio-injection=enabled 

# label should be visible here
kubectl describe ns default

# access kiali 
minikube service kiali -n istio-system
