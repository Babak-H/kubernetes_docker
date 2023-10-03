# create a argocd namespace and apply its installation file, inside the target kubernetes cluster system
kubectl create namespace argocd

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Change the argocd-server service type to LoadBalancer:
# loadbalancer address is where we can access the Argo UI
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# port forward the server so it can be available on UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# user/pass for logging into server
# default username is "admin"
# The initial password for the admin account is auto-generated and stored as clear text in the field password in a secret named argocd-initial-admin-secret
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo


# adding cluster to ArgoCD
# This step registers a cluster's credentials to Argo CD, and is only necessary when deploying to an "external cluster". When deploying internally (to the same cluster that Argo CD is running in), https://kubernetes.default.svc should be used as the application's K8s API server address.

# ist all clusters contexts in your current kubeconfig
kubectl config get-contexts -o name
# add a cluster from the above listed contexts
argocd cluster add <CONTEXT-NAME>


# add application to Cluster from IaC repo
# create a new project from a git repository into the k8s cluster, into namespace
argocd app create express-backend --repo https://github.com/LukeMwila/mock-express-backend.git --path raw-manifests --dest-server https://kubernetes.default.svc --dest-namespace express-nodejs

# in case of microservice => first create a "project" => then create "application" inside the project

# view the applications info
argocd app get express-backend

# at this point application still is  NOT fully deployed, synch it!
# This command retrieves the manifests from the repository and performs a kubectl apply of the manifests
argocd app sync express-backend

