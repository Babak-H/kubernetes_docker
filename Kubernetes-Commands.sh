#!/usr/bin/env bash

#####################################################################################
##### Installations #################################################################

# install Homebrew (brew) on macOS
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# install minikube
brew update
brew install hyperkit
brew install minikube

# install kubectl on macOS:
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/arm64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
sudo chown root: /usr/local/bin/kubectl
# or
brew install kubectl

kubectl version --client

# install kind (minikube alternative)
brew install kind
kind create cluster

brew install helm
helm --version

# on Linux
sudo snap install helm
# or
sudo snap install helm --classic

# on Ubuntu
curl -fsSL https://baltocdn.com/helm/signing.asc | sudo gpg --dearmor -o /usr/share/keyrings/helm.gpg
sudo apt-get install apt-transport-https --yes
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# make sure it works properly
kubectl version --client
minikube version

# start it
minikube start

# view all available nodes
kubectl get nodes

# get current status
minikube status

# version of kubectl CLI
kubectl version

# add ingress to minikube
minikube addons enable ingress

# how to run metrics-server on a Kubernetes cluster
# metrics-server collects CPU and memory metrics from nodes and pods.
# show all addons
minikube addons list
# enable metrics server addon for our cluster
minikube addons enable metrics-server
# or
git clone https://github.com/kodekloudhub/kubernetes-metrics-server.git
cd kubernetes-metrics-server/ || exit
kubectl create -f .

# find what ip address the kubernetes master is running at
kubectl cluster-info

# In Kubernetes versions : X.Y.Z  1.2.2
# Where X=1 stands for major, Y=2 stands for minor and Z=2 stands for patch version.

#####################################################################################
##### Shortcuts ##########################################################################

alias k=kubectl
export ns=default
alias k='kubectl -n $ns'
alias kdr='kubectl -n $ns -o yaml --dry-run'
alias kgp='kubectl get pods'
kgp # will show all running pods

vim ~/.vimrc
# set nu
# set expandtab
# set shiftwidth=2
# set tabstop=2

# po      POD
# rs      ReplicaSet
# deploy  Deployment
# svc     Service
# ns      NameSpace
# netpol  NetworkPolicies
# pv      PersistentVolume
# pvc     Persistent Volume Claim
# sa      Service Account
# cm      ConfigMap

# kubectl [command] [TYPE] [NAME] -o <OUTPUT_FORMAT>

# -o json : Output a JSON formatted API object
# -o name : Print only the resource name and nothing else
# -o wide : Output in the plain-text format with any additional information
# -o yaml : Output a YAML formatted API object

# everything in default namespace
k get all
# everything in all namespaces
k get all -A

# get all components of an application
k get all | grep AppName
k get all | grep mongodb

# get all namespaced resources
k api-resources # all resources available
k api-resources --namespaced -o=name  # get the names of all namespaced resources

# CTRL+R: type the start of a previous command, search shell history, and press Enter to re-run it.

#####################################################################################
##### POD ##########################################################################

# show all pods
k get pod
# get more info about the pods
# also shows the nodes that pods sit on
k get pod PodName -o wide

k get pod --all-namespaces
k get pod -A

k get pod PodName -o yaml > pod-definition.yaml
k get pod webapp-color -o yaml > pod.yaml  # get the pod and save it as yaml
vi pod.yaml  # edit the env variable in the config file
k replace -f pod.yaml --force  # instead of deleting and recreating, replace the pod with new one

# after editing an existing pod, even if it is unsuccessful, kubectl saves a version of the file in /tmp that you can use.
# this will replace the pod that you wanted to edit
kubectl replace -f /tmp/kubectl-edit-XXXXX.yaml --force

# find all pods that have color labels red, orange, or blue, and only show their "Name" column.
k get po -n rep -l "color in (red,orange,blue)" -o wide | grep -v Name | awk '{print $1}' > /home/ubuntu/pod001

# --dry-run: By default, as soon as the command is run, the resource will be created. If you simply want to test your command, use the --dry-run option. This will not create the resource. Instead, tell you whether the resource can be created and if your command is right.
# -o yaml: This will output the resource definition in YAML format on the screen.

# get only events for a pod
k get event -n dev-ns --field-selector involvedObject.name=MY-POD-ID

# get pod's ip address
k get pod nginx -o wide

# show the pod history logs
k logs PodName
k logs nginx-depl-5c8bf76b5b-5k52h

k logs -f my-pod # see live logs
k logs -f my-pod -c first-container # logs of specific container in multi-container pod

# If pod crashed and restarted, get logs about the previous instance (previous version before the update)
k logs nginx -p

# Find crashed pods:
kubectl get pods -n NAMESPACE -o wide | grep crash

# get logs for container log-x in pod dev-pod-dind-878516, get all the warnings, and redirect them to file /opt/dind-878516_logs.txt
k logs dev-pod-dind-878516 -c log-x | grep -i WARNING > /opt/dind-878516_logs.txt

k get po --all-namespaces | grep e-com-1123
k logs e-com-1123 -n e-commerce > /opt/output/e-com.log

# reach a service from within another pod in cluster
k run busybox --image=busybox --command -- wget -qO my-app-svc
k logs busybox  # the downloaded html from nginx deployments should be visible

# get how many lines we have in the logs combined for all the pods that have the tag "app=prod"
k logs -n ca2 -l app=prod | wc -l  > /home/ubuntu/res.txt

# Enabling debug logs is done by appending --verbosity=debug to the command of the main container in the deployment k8s yaml:
kubectl edit deployment vt-ledger-balances-processor
# add "- --verbosity=debug" under "spec.template.spec.containers[0].command"
# Then rollout restart the deployment:
kubectl rollout restart deployment vt-ledger-balances-processor

# show details of a running pod
k describe pod PodName
k describe pod mongo-depl-5fd6b7d4b4-dvlx6
k describe pods | grep --context=10 Events

# similar to docker images, go into a pod OS as root user
k exec -it PodName -- bin/bash
k exec -it PodName-1 -- sh

k exec -it mongo-depl-5fd6b7d4b4-dvlx6 -- bin/bash
# get inside the main container of the pod (when we also have sidecar container)
k exec -it nginx-webapp-7anc5464m -c main-container -- /bin/sh

# exec into the cockroach client pod, run sql client with the url of the database
k exec -it cockroach-client-0 -n 105250-cockroach-sql-client -- ./cockroach sql --url="postgresql://hault@cockroach/*****"

kubectl exec -it -n core-hault hault-restore-0 -c cockroach-1 -- sh

# execute one command inside the pod
k exec webapp -- cat /log/app.log
# show all environment variables inside the pod
k exec -it nginx -- env

# get all the environment variables from a pod
k exec nginx -- env

k run nginx --image=nginx
k run nginx --image=nginx -- /bin/sh -c 'echo hello world'
k run nginx --image=nginx --restart=OnFailure --port=80 -n mynamespace --env=HOSTNAME=local --labels=bu=finance,ENV=dev --requests='cpu=100m,memory=256Mi' --limits='cpu=200m,memory=512Mi' --dry-run=client -o yaml

k run nginx --image=nginx:alpine --dry-run=client -o yaml > nginx.yaml
# this will add the port 80 on pod (as containerPort) but won't create the service
k run custom-nginx --image=nginx --port=8080

# adds the label: tier:msg to the pod metadata
k run messaging --image=redis:alpine -l tier=msg

# Create a busybox pod (using kubectl command) that runs the command "env". Run it and see the output
k run busybox --image=busybox -- env
k run busybox --image=busybox --dry-run=client -o yaml --command env > pod.yaml
k run busybox --image=busybox --dry-run=client -o yaml --command -- /bin/sh -c 'echo hello; sleep 3600' > pod.yaml

k run client -n skynet --image=appropriate/curl --restart=Never -it --rm -- curl http://t2-svc:8080 > /home/ubuntu/svc-output.txt

k edit pod PodName

# has a section called "status" to see the state of the pod
k  describe pod

# copy file from pod to local machine and vice-versa
# k cp -n <namespace> <pod-name>:<path> <destination-on-local-system>
k cp -n default my-pod:/path/to/file.txt my-file.txt
# kubectl cp -n <namespace> <source> <pod-name>:<path>
k cp -n default file.txt my-pod:/path/to/file.txt

k cp -n vault-operators crown-operator-XXXXX:/var/run/kubernetes.io/serviceaccount/data/ca.crt  ./cert_operator-sa

k cp -n 105250-vault-operators ./script.sh vault-operator-tqdcf:/tmp/ -c installer-prerequisite-configuration-container

# Create a busybox pod with 'sleep 3600' as arguments. Copy '/etc/passwd' from the pod to your local folder
k run busybox --image=busybox -- bin/sh -c "sleep 3600"
k cp default/busybox:/etc/passwd /root/passwd # since we are copying a file we should give it a name in local folder too

# this command will make the file inside the local machine, but i want it to be created inside the same pod
kubectl exec vt-tools-repub-cron-28941778-65k7z -n 432235-vt-operators -- ./scripts/vt_list_postings_failures.sh > /tmp/temp_ids.txt
# To create a file inside the same pod where the script is executed, redirect the output within the context of the pod itself. You can do this by including
# the redirection as part of the command executed by kubectl exec
kubectl exec vt-tools-repub-cron-28941778-65k7z -n 432235-vt-operators -- sh -c './scripts/vault_list_post_postings_failures.sh > /tmp/temp_ids.txt'
# sh -c: This tells the shell to execute the following string as a command. It's necessary because the redirection (>) needs to be interpreted by the shell within the pod.
# './scripts/vault_list_post_postings_failures.sh > /tmp/temp_ids.txt': This is the command string that gets executed inside the pod. The script's output is redirected to /tmp/temp_ids.txt within the pod's filesystem.


# create a busybox pod and wget the above nginx pod's main page
k run busybox --image=busybox --command -- wget -O- NGINX_IP_ADDRESS:PORT

# replicaSet doesn't automatically delete older pods, we have to delete all older pod with wrong name manually
# delete all of them based on their tag
k delete pod -l name=busybox-pod
# delete the pod forcefully with a 0 grace period
k delete po busybox --force --grace-period=0

# Add an annotation 'owner: marketing' to all pods having 'app=v2' label
k annotate pod -l app=v2 owner=marketing

# Remove the 'app' label from the pods we created before
k label pod nginx{1..3} app-

# add several labels to a kubernetes serviceaccount via commandline
kubectl label serviceaccount SERVICEACCOUNT_NAME -n NAMESPACE key1=value1 key2=value2 key3=value3
kubectl label serviceaccount my-serviceaccount -n default env=production team=devops

# Annotate pods nginx1, nginx2, nginx3 with "description='my description'" value
# annotating 3 pods all at once
k annotate pod nginx{1..3} description="my description"

# k annotate --overwrite => overwrite the existing annotation with same name
# tmcomponent => resource type (it is a CRD type)
# observability => name of the tmcomponent resource object
# tmcomponent.tmachine.io/continuous-reconcile=true => key and value for annotation
k annotate --overwrite tmcomponent observability tmcomponent.tmachine.io/continuous-reconcile=true
k annotate --overwrite tmcomponent observability tmcomponent.tmachine.io/continuous-reconcile=one-shot

# Check the annotations for pod nginx1
k describe pod nginx1 | grep -i annotations
# delete annotation "owner" from pods
k annotate nginx{1..3} owner-

# show the pod with all their labels
k get pod --show-labels
# change the labels on the pod (update the label value) from app=v1 to app=v2
k edit pod nginx # then edit label and exit
# or
k label pod nginx app=v2 --overwrite
# only show the pods that contain label app=v2
k get pod -l app=v2
# or
k get pod --selector=app=v2

# Add a new label tier=web to all pods having 'app=v2' or 'app=v1' labels
k label pod -l "app in (v1,v2)" tier=web
# add app=cloudacademy label to all pods that have the label env=prod
k label po -n gzz -l "env=prod" app=cloudacademy

# how to choose a pod via -l, based on its labels
k get pods --selector app=App1
k get pods -l app=App1
k get pods -l env=dev
k get pod -l env=prod,bu=finance,tier=frontend
# get all objects with "prod" label for "env"
k get all -l env=prod

# Change pod's image to nginx:1.7.1 from nginx:1.6.1
k set image pod nginx nginx=nginx:1.7.1

# how to check a pod's liveness or readiness probes
k describe pod nginx | grep -i liveness
k describe pod nginx | grep -i readiness

# Lots of pods are running in qa,dev,test,production namespaces. All of these pods are configured with liveness probe. Please list all pods whose liveness probe are failed
# liveness or readiness probe failures are saved as "events"
k get events -o json | grep -i liveness

# Create a busybox pod that runs  i=0; while true; do echo "$i: $(date)"; i=$((i+1)); sleep 1; done
k run busybox --image=busybox --command -- /bin/sh -c 'i=0; while true; do echo "$i: $(date)"; i=$((i+1)); sleep 1; done'
k logs busybox # to see the results of the command

# this will cause the pod to crashloop backoff
k run busybox --image=busybox --command -- /bin/sh -c echo "hello"
# but this will work; after sh -c, quote the command with "" or ''.
k run busybox1 --image=busybox --command -- /bin/sh -c 'echo "hello"'

# In this command, echo 'hi' is treated as an argument to the default entry point of the nginx image. The nginx image has a default entry point that starts the Nginx server,
# and the echo 'hi' is passed as an argument to this entry point. However, since the Nginx server does not recognize echo 'hi' as a valid argument, the container will likely
# fail to start or exit immediately.
k run nginx --image=nginx -- echo 'hi'

# In this command, the --command option tells Kubernetes to override the default entry point of the container with the command specified after -- , This means that instead
# of starting the Nginx server, the container will execute echo 'hi' as the main command. As a result, the container will start, execute the echo 'hi' command, print
# "hi" to the standard output, and then exit.
k run nginx --image=nginx --command -- echo 'hi'

# create a pod that echoes "hello world", does not restart, and is deleted when it completes.
k run busybox --image busybox -it --rm --restart=Never -- /bin/sh -c 'echo hello world'
k get po

# list all pods and their nodes
kubectl get pod -o wide
kubectl get pods --all-namespaces
kubectl get pod --all-namespaces -o json | jq '.items[] | .spec.nodeName + " " + .status.podIP'

#####################################################################################v
##### ReplicaSet ##########################################################################

k get replicaset new-replicaset -o wide

# have to delete all pods to take effect
k edit replicaset myReplicaSet

k scale rs new-replicaset --replicas=5

# show all replica sets
k get rs

# if a Deployment or ReplicaSet does not have ready pods, check events and image names for image pull issues.
k describe rs rs-d23423
k edit rs rs-d23423 # correct the image name

#####################################################################################
##### Deployment ##########################################################################

# show all deployments
k get deploy
k get deploy -A

k create deploy myDeploy --image=myImage
k create deploy nginx-depl --image=nginx
k create deploy mongo-depl --image=mongo

k create deploy nginx --image=nginx --dry-run=client -o yaml
k create deploy nginx --image=nginx --dry-run=client -o yaml > nginx-deploy.yaml
k apply -f nginx-deployment.yaml

k create deploy webapp --image=kodekloud/webapp --replicas=3
k create deploy httpd-frontend --image=httpd:2.4-alpine --replicas=4

k edit deploy nginx-depl
# edit deployment
k describe deploy nginx-depl

k get deploy nginx-depl -o yaml > nginx-deployment.yaml

k delete deploy nginx-depl
k delete -f nginx-deployment.yaml

# with Deployments you can edit fields in the pod template, since the pod template is part of the Deployment specification.
# With every pod-template change, the Deployment creates a new ReplicaSet and rolls out new Pods.
# so we can edit anything inside the deployment via "k edit deploy ..." command

# update image container of a deployment
k set image RESOURCE_TYPE/RESOURCE_NAME CONTAINER_NAME=IMAGE_NAME_WITH_TAG
k set image deployment/client-deployment client=fhsinchy/notes-client:edge

k set image deploy cloudforce -n fre nginx=nginx:1.19.0-perl --record

k scale deploy nginx --replicas=5

# instead of deleting a deployment, we can just scale it to 0 and then later increase the size
kubectl scale deployment prometheus-operator-105250-core-vault -n 105250-core-vault-mon --replicas=0

# get Deployment or Pod logs
k logs my-depl
k logs -f my-depl

# Create a deployment with image nginx:1.18.0, called nginx, having 2 replicas, with port 80
k create deploy nginx --image=nginx:1.18.0 --replicas=2 --port=80
# view the replicaset for this deployment
k describe deploy nginx # there is a section: "NewReplicaSet: nginx-dbdf9c499 (2/2 replicas created)"
k get rs nginx-dbdf9c499 -o yaml

k create deploy redis --image=redis:alpine --replicas=3
k expose deploy redis --port 6379 --name redis-svc  # by default ClusterIP service is created

k expose deploy my-webapp --type NodePort --name front-svc --port 80 --dry-run=client -o yaml > svc.yaml
# in spec.ports.[0] add "nodePort: 30083"

# if you update deployment to wrong image, the "k get deploy" might show nothing wrong, but "k get pod" will show one pod error "ErrImagePull"

# Create a deployment called foo using image 'dgkanatsios/simpleapp' (a simple server that returns hostname) and 3 replicas. Label it as 'app=foo1'. Declare that containers in this pod will accept traffic on port 8080
k create deploy foo --image=dgkanatsios/simpleapp --port=8080 --replicas=3
k label deploy foo --overwrite app=foo1
# or edit the deployment file and change the line for label

# create service for deployment foo on port 6262
k expose deploy foo --port 6262 --target-port 8080

# To access a Kubernetes pod via a browser, you typically need to expose the pod using a Kubernetes Service. This service can be of type NodePort, LoadBalancer, or Ingress,
# depending on your cluster setup and requirements
kubectl expose pod POD_NAME --type=NodePort --port=PORT
kubectl get service POD_NAME
# You can now access the application running in your pod by navigating to http://<node-ip>:<node-port> in your browser. Replace <node-ip> with the IP address of any of your
# cluster nodes and <node-port> with the NodePort you obtained in the previous step.

# If you're running Kubernetes on a cloud provider, you might prefer using a LoadBalancer service type, which will provide an external IP address. Alternatively, for more complex routing, you can set up an Ingress resource.
# Remember that exposing a pod directly might not be the best practice for production environments. It's usually better to expose a deployment or a set of pods using a service to ensure high availability and load balancing.

# copy file from Pod to local machine
k cp default/postgresl-deploy:/home/backup/db ./Desktop/mydb1.dmp

# deployment does NOT have --command flag, use -- instead
k create deploy reddit-1 --image=reddit:alpine -n web --replicas=2 --dry-run=client -o yaml -- sleep '4h' > deploy.yaml

# Is there any way to add labels in .spec.template after a deployment has been created?
k label deployment myDeployment myLabelKey=myLabelValue

# But this would only add the label to .metadata.labels. I would like to add a label to .spec.template.metadata.labels.

# This should be possible using the kubectl patch command. The following patch file would add a new label to the spec.template.metadata.labels property
# spec:
#   template:
#     metadata:
#       labels:
#         myLabelKey: myLabelValue

k patch deployment myDeployment --patch "$(cat patchfile.yaml)"

# or
k patch deployment myDeployment --patch '{"spec": {"template": {"metadata": {"labels": {"myLabelKey": "myLabelValue"}}}}}'

# why adding a label to a Deployment does not add the label to its Pods?
# Labels on Deployments and Pods created from Deployments are separate. If you want labels to appear on the Pods, add them to the pod template in the Deployment
# definition, not the deployment itself.

#####################################################################################
##### Service ##########################################################################

k get service
k get svc

k describe service nginx-service

# this command opens the Service URL from minikube. For NodePort Services, minikube provides a reachable node IP and port.
minikube service serviceName
minikube service mongo-express-service

# expose a pod via a Service (ClusterIP)
k expose pod redis --port 6379 --name redis-service --dry-run=client -o yaml > svc.yaml

# this does NOT expose any specific pod because it has no selector; edit the YAML file and add a selector manually.
k create svc clusterip redis --tcp=6379:6379 --dry-run=client -o yaml > my-svc.yaml

k create svc nodeport nginx --tcp=80:80 --node-port=30080 --dry-run=client -o yaml

# edit the Service file if you need to set a specific nodePort manually.
k expose deploy frontend --type NodePort --name frontend-service --port 6262 --dry-run=client -o yaml > svc.yaml

k expose deploy redis --port 6379 --name messaging-service -n marketing

# create an nginx Pod with containerPort 80, then expose it as a ClusterIP Service.
k run nginx --image=nginx --port=80
k expose pod nginx --port=80 --target-port=80

# see all endpoints and ports that are exposed by Services
k get endpoints

# this shows the target port
k describe svc back-end

#####################################################################################
##### ConfigMap / Secret ##########################################################################

k apply -f config-file.yaml

k get cm
k get configmap

# encrypt a normal string called "username"|"password" into base64
echo -n 'username' | base64
echo -n 'password' | base64

echo -n 'mysql' | base64
echo -n 'dfdsfsW=' | base64 --decode

k create cm test-config --from-literal=APP_COLOR=blue --from-literal=APP_NAME=webapp
k create cm test-config-1 --from-file=test-config.properties

k create cm special-config --from-literal=special.how=very --from-literal=special.type=charm

# shows the secret values
k get secret

# imperative command to create new object
# kubectl create \                    # type of the object we are creating
#   secret \                          # type of secret
#   generic SECRET_NAME \             # for later reference in a pod config
#   --from-literal PGPASSWORD=password123

k create secret generic test-secret --from-file=secret.properties
k create secret generic test-secret --from-literal=DB_HOST=mysql

# create secret of type TLS
k create secret tls webhook-server-tls -n webhook-ns \
  --cert "/root/keys/webhook-server-tls.crt" \
  --key "/root/keys/webhook-server-tls.key"

k create cm cm-3392845 --from-literal=DB_NAME=SQL3322 --from-literal=DB_HOST=sql322.mycompany.com --from-literal=DB_PORT=3306
k create secret generic db-secret-xxdf --from-literal=DB_HOST=sql01 --from-literal=DB_USER=root --from-literal=DB_PASSWORD=password123

# Create and display a configmap from a .env file
cat config.env

# var1=val1
# # this is a comment
# var2=val2
# # another comment

k create cm my-cm --from-env-file=config.env

#####################################################################################
##### NameSpace ##########################################################################

# get all the available namespaces
k get namespace
k get ns

# create component inside a namespace (if it is not defined inside config file)
k apply -f mysql-configmap.yaml -n dev

k create ns apx-z99
k create ns dev-ns --dry-run=client -o yaml > dev-ns.yaml
k create ns test-ns --dry-run=client -o yaml

# shows the current kubeconfig context
k config current-context

# change the default namespace
k config set-context $(k config current-context) -n dev
k get ns

#####################################################################################
##### ServiceAccount ##########################################################################

k create serviceaccount NAME
k create sa NAME
k create token SA-NAME
k get sa

# set the serviceAccount for deployment called "frontend" to "myuser"
k set serviceaccount deploy frontend myuser

# view user accounts
k config view users
# view service accounts
k config view sa

# create a new SA called tiller in kube-system namespace
k create serviceaccount -n kube-system tiller

#####################################################################################
##### metrics-server ##########################################################################

# shows how much memory/cpu each node is using
k top node
# shows how much memory/cpu each pod is using
k top pod

#####################################################################################
##### Ingress ##########################################################################

# how to see if the ingress controller is installed
k get ingress -n dashboard-ingress
# same as above with more info
k get ingress -n dashboard-ingress --watch

k describe ingress ingress-wear-watch

k get ingress -A

# get the pod related to nginx controller
k get pods -n ingress-nginx

# view ingress controller
kubectl get pod -n kube-system | grep ingress

# create ingress resource via command:
k create ingress ingress-test --rule="wear.my-online-store.com/wear*=wear-service:80"
k create ingress ingress-test --rule="wear.my-online-store.com/wear*=wear-service:80" --dry-run=client -o yaml > my-ingress.yaml

# create ingress for service "my-video-service" to be available from "http://ckad-mock-exam-solution.com:30093/video"
# 30093 is port on Ingress NOT on service
k get svc # get port on the service
k create ingress ingress-service --rule="ckad-mock-exam-solution.com/video*=my-video-service:8080" --dry-run=client -o yaml > ingress.yaml

k create ingress pong -n ing-internal --rule="/hello=hello:5678" --dry-run=client -o yaml > ing.yaml
k get nodes -o wide
curl -KL NODE-INTERNAL-IP/hello

#####################################################################################
##### HPA Horizontal Pod Autoscaler ##########################################################################

k apply -f my-hpa.yaml

# get autoscaler status
k get hpa my-hpa

# delete hpa autoscaler
k delete -f my-hpa.yaml
k delete hpa my-hpa

# Autoscale the deployment, pods between 5 and 10, targeting CPU utilization at 80%
k autoscale deploy nginx --cpu-percentage=80 --min=5 --max=10
k get hpa nginx

k autoscale deploy php-apache --cpu-percentage=50 --min=1 --max=10

k -n xx1 autoscale deploy eclipse --min=2 --max=4  --cpu-percentage=65

#####################################################################################
##### PV and PVC ##########################################################################

k get pv
k get pvc
k get storageclass
# or
k get sc

# a PVC can only be fully deleted after no running Pod is using it.
k delete pvc myclaim

# check pvc events/status
k describe pvc local-pvc
# get pvc events
k -n earth describe pvc earth-project-earthflower-pvc # event section is at the end

kubectl get pvc -n 105250-core-vault | grep prometheus-postgres
kubectl delete pvc -n 105250-core-vault prometheus-postgres-db-prometheus-postgres-{0..2}

#####################################################################################
##### Rolling Updates ##########################################################################

# get the progress of the update status
k rollout status deploy nginx-depl

# Update the nginx image to nginx:1.19.8
k edit deploy nginx  # change the .spec.template.spec.containers[0].image
# or
k set image deploy nginx nginx=nginx:1.19.8

# Pause the rollout of the deployment
k rollout pause deploy nginx
# then resume
k rollout resume deploy nginx

# get history of the deployment rolling updates as a list
k rollout history deploy nginx-depl

# rollback the deployment update to specific revision
k rollout undo deploy nginx-depl --to-revision=2
# rollback the deployment to previous change
k rollout undo deploy nginx-depl

# check to see if the change has been applied to all the pods in deployment
k rollout status deploy my-deploy

# shows all change history, each change is called "Revision"
k rollout history deploy my-deploy

# with the --record flag, rollout history can show the command that caused each change.
k create -f deploy-file.yaml --record

# revision 1 is the first version where the deployment was created.
# You can check the status of each revision individually by using the --revision flag:
k rollout history deploy nginx --revision=1

# rollback; the Deployment rolls Pods back gradually according to the rollout strategy.
k rollout undo deploy my-test-deploy
k rollout undo deploy nginx --to-revision=2

# how to restart the whole deployment step-by-step
# the pods will be restarted based on max surge and max unavailable values
k rollout restart deploy -n 105250-core-vault

#####################################################################################
##### Patch ##########################################################################

k patch -n kube-system daemonset/istio-cni-node --type json -p='[{"op": "remove", "path": "/spec/template/spec/containers/0/resources/limits/cpu"}]'
k patch -n kube-system clusterrole/istio-cni --type json -p='[{"op": "add", "path": "/rules/0/verbs", "value": ["get", "list", "watch", "delete"]}]'

k set env -n kube-system daemonset/istio-cni-node REPAIR_DELETE_PODS="true" REPAIR_REPAIR_PODS="false"

k get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/core-vt/deployments.apps/postings-processor/max_service_consumer_group_lag" | jq
k get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/VAULT_NS/deployments.apps/DEPLOYMENT_NAME/max_service_consumer_group_lag" | jq
k get --raw "/apis/custom.metrics.k8s.io/v1beta1"

#####################################################################################
##### Roles and RoleBindings ##########################################################################

k get role
k get rolebinding
k describe role developer
k describe rolebinding devuser-developer-binding

# check whether you can perform an operation
k auth can-i create deployments
k auth can-i delete nodes

# test if another user can perform an operation. You usually need admin permissions to impersonate another user.
k auth can-i create deployments --as dev-user
k auth can-i delete nodes --as dev-user
k auth can-i create pods --as dev-user --namespace test

# This command will output yes or no to indicate whether the action is allowed.
kubectl auth can-i list deployments --as system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT_NAME
# The if statement should compare the output of the kubectl auth can-i command to the string yes, not the exit status ($?). The exit status of kubectl auth can-i is always 0
# unless there's an error in executing the command itself.

# you can add or remove permissions from a Role by editing it.

k get clusterRole
# get how many cluster roles exist in default namespace
k get clusterRole --no-header | wc -l
k get clusterRoleBinding --no-header | wc -l

# you can see the subject of this RoleBinding is system:bootstrappers:kubeadm
k describe rolebinding kube-proxy -n kube-system

# You have been asked to create a new ClusterRole for a deployment "pipeline" and bind it to a specific ServiceAccount scoped to a specific namespace.
# Create a new ClusterRole named "deployment-clusterrole", which only allows to create the following resource types: "Deployment, StatefulSet, DaemonSet"
# Create a new ServiceAccount named "cicd-token" in the existing namespace "app-team1". Bind the new ClusterRole "deployment-clusterrole" to the new ServiceAccount "cicd-token",
# limited to the namespace "app-team1".
k create clusterrole deployment-clusterrole --verb=create --resource=deployment,statefulset,daemonset
k create serviceaccount cicd-token -n app-team1
# bind the ClusterRole to the ServiceAccount only inside namespace app-team1.
k create rolebinding deployment-clusterrolebinding -n app-team1 --clusterrole=deployment-clusterrole --serviceaccount=app-team1:cicd-token
k auth can-i create deployment -n app-team1 --as=system:serviceaccount:app-team1:cicd-token # yes
k auth can-i create secret -n app-team1 --as=system:serviceaccount:app-team1:cicd-token # no

# create a new serviceAccount with name "pvviewer", grant this SA access to "list all PVs" in the cluster by creating correct ClusterRole called
# "pvviewer-role" and clusterRoleBinding called "pvviewer-role-binding"
k create serviceaccount pvviewer
k get sa
k create clusterrole pvviewer-role --verb=list --resource=persistentvolumes
k create clusterrolebinding pvviewer-role-binding --clusterrole=pvviewer-role --serviceaccount=default:pvviewer
k auth can-i list persistentvolumes --as=system:serviceaccount:default:pvviewer # yes

# create a new serviceAccount "gitops" in namespace "project-1". Create role and rolebinding both named "gitops-role" and "gitops-rolebinding". Allows the SA
# to create secrets and configmaps in the namespace
k create serviceaccount gitops -n project-1
k create role gitops-role -n project-1 --verb=create --resources=secrets,configmaps
k create rolebinding gitops-rolebinding -n project-1 --role=gitops-role --serviceaccount=project-1:gitops
k auth can-i create secret -n project-1 --as system:serviceaccount:project-1:gitops

#####################################################################################
##### Job ##########################################################################

k get job

k delete job math-add-job
kubectl delete -f job-definition.yaml

# create a job
k apply -f job-definition.yaml

# imperative way to create a job
k create job throw-dice-twice --image=kodekloud/throw-dice --dry-run=client -o yaml > test-job.yaml

k create job whalesay --image=docker/whalesay --dry-run=client -o yaml > job.yaml
k get job whalesay
k logs job/whalesay

k create job pi --image=perl:5.34 -- perl -Mbignum=bpi -wle 'print bpi(2000)'
k logs job/pi # how to get job's results in logs

# in status you can see how many times job succeeded or failed
k describe job throw-dice-twice

k get cronjob

# create a Job from a CronJob
k create job --from=cronjob/sample-cron-job sample-job

# Create a cron job with image busybox that runs on a schedule of "*/1 * * * *" and writes 'date; echo Hello from the Kubernetes cluster'
k create cronjob busybox --image=busybox --schedule="*/1 * * * *" -- /bin/sh -c 'date; echo Hello from the Kubernetes cluster'

#### StatefulSet ##########################################################################

# install StatefulSet via helm chart Operator
helm install prometheus stable/prometheus-operator

k get statefulset
k describe statefulset prometheus-oper-prometheus > prometheus-operator.yml
cat prometheus-operator.yml

# grafana uses ClusterIP by default, so we can use port forwarding to access it from outside the cluster.
k get pod  # find the name of the pod where grafana is running.
# open the logs for grafana pod and check which port it is listening on
k logs GRAFANA_POD_NAME -c grafana
# port forward so we can access it from outside the cluster.
# user/pass for grafana login can be found in the Helm chart documentation.
k port-forward deploy prometheus-grafana 80:3000

# If you're thinking of a way to quickly access a pod for testing or development purposes without setting up a service, you might be referring to using kubectl port-forward.
# This command allows you to forward a port from your local machine to a port on a pod. Here's how you can do it:
kubectl port-forward pod/POD_NAME LOCAL_PORT:POD_PORT
# Once the port forwarding is set up, you can access the application by navigating to http://localhost:<local-port> in your browser.
# This method is particularly useful for development and debugging purposes, as it allows you to access a pod directly without modifying your cluster's network configuration.
# However, it's not suitable for production use, as it only works while the kubectl port-forward command is running and is limited to your local machine.

##### Nodes and Cluster Configurations #####

# information about public-space namespace and the cluster
# find what ip address the kubernetes master is running at
k cluster-info

# show all the components inside the default namespace, related to kube-api
k api-resources --namespaced=false

k api-resources

# *** login to Kubernetes Cluster via OIDC
curl -s -L https://artifactory.XXXX.XXXXXX.net/artifactory/XXXXX/k8s-oidc-client/k8s-oidc-client-init.sh

# OpenID Connect (OIDC) is an identity layer built on top of the OAuth 2.0 framework
k8s-oidc-client --dev
# or, this one opens a web browser
k8s-oidc-client --dev --web-login

# select the cluster
k config get-contexts
k config use-context DEV_CONTEXT

k config set-context myContext -n dev-ns

# check if the user can have access to do an action
k auth can-i create deploy -n dev

# etcd client
apt-get install etcd-client
k get pod etcd-controlplane -n kube-system

# check if etcd is encrypted at rest or not
ps -aux | grep kube-api | grep "encryption-provider-config"

# can see all assigned labels to this node
k describe nodes node01

# all user access, whether from kubectl or direct API access, goes through kube-apiserver.
# this is how an outside user can access kube-apiserver via certificate.
curl https://my-kube-playground:6443/api/v1/pods \
  --key admin.key
  --cert admin.crt
  --cacert ca.crt

cat $HOME/.kube/config

# change the current context
k config use-context pod-user@production
k config view

# use the kubeconfig file to connect to the kube-api
k config --kubeconfig=/root/my-kube-config use-context research
k config --kubeconfig=/root/my-kube-config current-context

# check the authorization modes on the cluster
k describe pod kube-api-server-controlplane -n kube-system | grep authorization-mode

# get the API groups and resource names from command
k api-resources

# view list of enabled admission controllers
kube-apiserver -h | grep enable-admission-plugins

cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep enable-admission-plugins

# if you are running kube-apiserver as a pod
ps -ef | grep kube-apiserver | grep admission-plugins

# returns the preferred version from the API
k explain deployment

# shows which API group and version the resource "job" has
kubectl explain job

# enable convert functionality on kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert"
sudo install -o root -g root -m 0755 kubectl-convert /usr/local/bin/kubectl-convert
k convert --help

# convert the YAML file for a Deployment from an older apps API version to apps/v1
k convert -f nginx.yaml --output-version apps/v1

k convert -f ingress-old.yaml --output-version networking.k8s.io/v1 > ingress.yaml
k apply -f ingress.yaml

# What is the preferred version for authorization.k8s.io api group?
kubectl proxy --port=8001 &  # & runs the command in the background and kubectl proxy starts the proxy to the Kubernetes API server.
curl localhost:8001/apis/authorization.k8s.io

# Enable the v1alpha1 version for rbac.authorization.k8s.io API group on the controlplane node.
cd /etc/kubernetes/manifests
vi kube-apiserver.yaml
# add
# --runtime-config=rbac.authorization.k8s.io/v1alpha1

# get info about specific section of a yaml object
kubectl explain cronjob.spec.jobTemplate --recursive

##########################################################################

# I have script A inside a pod in namespace 1 and want to execute it from another pod in namespace B. What is the correct command for this?
kubectl exec -n namespace-1 pod-name -- /path/to/script.sh


# In Kubernetes, you can't directly "mount" one deployment onto a job. However, you can share data between a deployment and a job using shared storage, such as a PersistentVolume (PV) and a PersistentVolumeClaim (PVC). This allows both the deployment and the job to access the same data.

# Create a PersistentVolume: This represents a piece of storage in your cluster.
# Create a PersistentVolumeClaim: This is a request for storage by a pod. Both the deployment and the job will use the same PVC to access the shared storage.
# Mount the PVC in both the Deployment and the Job: This allows both to read from and write to the same storage.

#####################################################################################
##### HELM ##########################################################################

# shows name of operating system
cat /etc/*release*

# retrieve helm client environment information
helm env
helm version
# helm verbose output
helm --debug

# search for a helm chart
helm search KEYWORD

# search the helm hub for a chart
helm search hub wordpress

# add the bitnami repository, each repository is an alternative to helm hub
helm repo add bitnami https://charts.bitnami.com/bitnami
# search for a chart inside the bitnami repo
helm search repo wordpress

# see list of all added repos
helm repo list

# install a helm chart
helm install LOCAL_NAME REPO/CHART_NAME

# each chart can be installed with different names several times
helm install release-1 bitnami/wordpress
helm install release-2 bitnami/wordpress

helm install bravo bitnami/drupal

# download and install a chart separately
helm pull --untar bitnami/wordpress
# ./wordpress => where the chart files are located at
helm install release-3 ./wordpress

helm pull --untar bitnami/apache

# download chart from local directory
helm pull prom-repo/kube-prometheus-stack

# list of all installed charts
helm list
# find pending helm charts in all environments
helm list --pending -A

# delete an installed chart
helm uninstall CHART_LOCAL_NAME
helm uninstall release-1
helm uninstall bravo

# upgrade an existing release with values from a custom values file.
helm upgrade release-1 REPO/CHART_NAME --values=my-values.yaml

# install chart with custom values "myvalues.yaml" with local name "myredis", the chart files are downloaded at location "./redis"
helm install -f myvalues.yaml myredis ./redis

# install a chart with default values, but change a specific one
# "version" is a variable at values.yaml file
helm install my-chart ./chart --set version=2.0.0

# save helm values in yaml file to use them later
helm show values prom-repo/kube-prometheus-stack > values.yaml

# Write the contents of the values.yaml file of the bitnami/node chart to standard output
helm show values bitnami/node

# Install the bitnami/node chart setting the number of replicas to 5
helm show values bitnami/node | grep -i replica # replicaCount: 1
helm install mynode bitnami/node --set replicaCount=5

# how to update a Helm release
helm upgrade release-1 REPO/CHART_NAME

# apply changes after updating values.yaml file
helm upgrade monitoring prom-repo/kube-prometheus-stack --values=values.yaml

# create a Chart from local provided files
helm create myChart

# this will inject the values into the chart to make sure that it works correctly
helm template -f values/test-values.yml myChart

# checks the YAML file syntax for both values files and Helm template files
helm lint -f values/test-values.yml myChart

# install our Helm chart:
helm install given_name chart_name -f values/alpha.yml

# install the chart into the cluster, this should be done for each chart that wants to be added into the cluster based on the chart
helm install -f values/test-values.yml release-chart myChart

# same as above, but this renders the release without installing it to make sure it works.
helm install release-chart myChart -f values/test-values.yml --dry-run

helm upgrade -f myvalues.yaml -f override.yaml redis ./redis

## HelmFile

# install helmfile tool, this is a plugin for Helm, allows installing several instances of the chart at once
brew install helmfile

# deploy helm charts via helmfile
helmfile sync

# shows all the applied charts
helmfile list

# delete all releases managed by the helmfile
helmfile destroy



# change the pod to run as ROOT user and add SYS_TIME capability
# kubectl get pod app-sec-kff345 -o yaml > app-sec.yaml
# vi app-sec.yaml
# do the editing
# k replace -f app-sec.yaml
