# You have been asked to create a new ClusterRole for a deployment pipeline and bind it to a specific ServiceAccount scoped to a specific namespace.
# Create a new ClusterRole named deployment-clusterrole, which only allows to create the following resource types: Deployment, StatefulSet, DaemonSet
# Create a new ServiceAccount named cicd-token in the existing namespace app-team1, Bind the new ClusterRole deployment-clusterrole to the new ServiceAccount cicd-token, limited to the namespace app-team1.
kubectl create clusterrole deployment-clusterrole --verb=create --resource=deployment,statefulset,daemonset -o yaml --dry-run=client | kubectl apply -f -
kubectl create serviceaccount cicd-token -n app-team1
kubectl create clusterrolebinding deployment-clusterrolebinding --clusterrole=deployment-clusterrole --serviceaccount=cicd-token --namespace=app-team1 -o yaml | kubectl apply -f -

kubectl auth can-i create deployment -n app-team1 --as system:serviceaccount:app-team1:cicd-token # yes
kubectl auth can-i create daemonset -n app-team1 --as=system:serviceaccount                       # no

# Set the node named ek8s-node-0 as unavailable and reschedule all the pods running on it.
kubectl get nodes
kubectl cordon ek8s-node-1
kubectl drain ek8s-node-1 --ignore-daemonsets
kubectl drain ek8s-node-1 --ignore-daemonsets --delete-eptydir-data
# or
kubectl drain ek8s-node-1 --ignore-daemonsets --force
kubectl get nodes

# Given an existing Kubernetes cluster running version 1.22.1, upgrade all of the Kubernetes control plane and node components on the master node only to version 1.22.2.
# Be sure to drain the master node before upgrading it and uncordon it after the upgrade
# You are also expected to upgrade kubelet and kubectl on the master node, do NOT upgrade the worker nodes, etcd, the containerv manager, the CNI plugins or the DNS service
# You are also expected to upgrade kubelet and kubectl on the master node.
kubectl config use-context mk8s
kubectl cordon mk8s-master-0
kubectl drain mk8s-master-0 --ignore-daemonsets
kubectl get nodes
ssh mk8s-master-0
sudo -i
sudo apt-mark unhold kubeadm && sudo apt-get update && sudo apt-get install -y kubeadm='1.32.x-*' && sudo apt-mark hold kubeadm
kubeadm version
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.32.x --etcd-upgrade=false --skip-phases=addon/coredns
sudo apt-mark unhold kubelet kubectl && sudo apt-get update && sudo apt-get install -y kubelet='1.32.x-*' kubectl='1.32.x-*' && sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload
sudo systemctl restart kubelet
exit
kubectl uncordon mk8s-master-0
kubectl get nodes

# create a snapshot of the existing etcd instance running at https://127.0.0.1:2379, saving the snapshot to /var/lib/backup/etcd-snapshot.db
# ca certificate => /opt/kuin/ca.crt   client certificate => /opt/kuin/etcd-client.crt  client-key => /opt/kuin/etcd-client.key
# restore an existing, previous snapshot located at /var/lib/backup/etcd-snapshot-previous.db
ETCDCTL_API=3 etcdctl --endpoints 127.0.0.1:2379 --cacert=/opt/kuin/ca.crt --cert=/opt/kuin/etcd-client.crt --key=/opt/kuin/etcd-client.key snapshot save /var/lib/backup/etcd-snapshot.db

ls /var/lib
mkdir -p /var/lib/new-etcd
ls -la /var/lib/backup/etcd-snapshot-previous.db
# make sure that etcd user owns it otherwise you need to be a root user and change owner permission then you need to restore db backup
ETCDCTL_API=3 etcdctl --endpoints 127.0.0.1:2379 --cacert=/opt/kuin/ca.crt --cert=/opt/kuin/etcd-client.crt --key=/opt/kuin/etcd-client.key snapshot restore --data-dir=/var/lib/new-etcd/ /var/lib/backup/etcd-snapshot-previous.db

vi /etc/kubernetes/manifests/etcd.yaml

    - hostPath:
    path: /var/lib/new-etcd/
    type: DirectoryOrCreate
    name: etcd-data

# Schedule a pod as follows:  Name: nginx-kusc00401,  Image: nginx,  Node selector: disk=ssd
kubectl get nodes -o wide --show-labels | grep -i disk=ssd 
# if not 
kubectl label node node01 disk=ssd

kubectl run nginx-kusc00401 --image=nginx --dry-run=client -o yaml > pod.yaml
vi pod.yaml

    apiVersion: v1
    kind: Pod
    metadata:
      labels:
        run: nginx-kusc00401
        name: nginx-kusc00401
    spec:
      containers:
      - image: nginx
        name: nginx
      # add node selector section
      nodeSelector:
        disk: ssd

kubectl apply -f pod.yaml


# Check to see how many nodes are ready (not including nodes tainted NoSchedule) and write the number to /opt/KUSC00402/kusc00402.txt.
echo $(kubectl get nodes --no-headers | grep -v 'NoSchedule' | grep -c 'Ready' | wc -l ) > opt/KUSC00402/kusc00402.txt
# or
kubectl get nodes -o=custom-columns=NodeName:.meta.name,TaintKey:.spec.taints[*].key,TaintValue:.spec.taints[*].value,TaintEffect:.spec.taints[*].effect 


# Monitor the logs of pod foo and: Extract log lines corresponding to error file-not-found, Write them to /opt/KUTR00101/foo 
kubectl config use-context k8s
kubectl get pods
kubectl logs foo | grep "error file-not-found" > /opt/KUTR00101/foo


# From the pod label name=overloaded-cpu, find pods running high CPU workloads and write the name of the pod consuming most CPU to the file /opt/KUTR00401/KUTR00401.txt (which already exists)
kubectl top pod -l name=overloaded-cpu --sort-by=cpu 
echo "POD-NAME" >> /opt/KUTR00401/KUTR00401.txt  # >> adds it to the files and empties whatever was inside of it 


# A Kubernetes worker node, named wk8s-node-0 is in state NotReady. Investigate why this is the case, and perform any appropriate steps to bring the node to a Ready state, ensuring that any changes are made permanent
kubectl config use-context wk8s 
kubectl get nodes 
kubectl describe nodes wk8s-node-0    # kubelet stopped sending status, Node status unknown
ssh wk8s-node-0 
sudo -i 
systemctl enable --now kubelet 
systemctl restart kubelet
systemctl status kubelet 
exit
kubectl get nodes 


# Taint the worker node to be Unschedulable. Once done, create a pod called dev-redis, image redis:alpine to ensure workloads are not scheduled to this worker node. Finally, create a new pod called prod-redis and image 
# redis:alpine with toleration to be scheduled on node01. Finally, create a new pod called prod-redis and image redis:alpine with toleration to be scheduled on node01.
kubectl get nodes
kubectl taint node node01 env_type=production:NoSchedule 
kubectl describe nodes node01 | grep -i taint 
kubectl run dev-redis --image=redis:alpine --dry-run=clinet -o yaml > pod-redis.yaml
kubectl apply -f pod-redis.yaml 
vi pod-redis.yaml

    apiVersion: v1 
    kind: Pod 
    metadata:
      name: prod-redis  # edit here
    spec:
      containers:
      - name: prod-redis # edit here 
        image: redis:alpine
      # edit here
      tolerations:
      - effect: Noschedule 
        key: env_type 
        operator: Equal 
        value: prodcution

kubectl create -f pod-redis.yaml 
kubectl get pods -o wide 


# join node01 worker node to cluster and you have to deploy pod on the node01, pod name should be web and image should be nginx
kubectl get nodes
ssh controlplane # in case we are not on master node
kubeadm token create --print-join-command  # save the command and use it on node01
ssh node01
kubeadm join 172.30.1.2:6443 --token TOKEN --discovery-token-ca-cert-hash CERT-HASH
# if there is any error here check the kubelet
systemctl status kubelet
systemctl start kubelet
systemctl status kubelet
exit
kubectl get nodes
kubectl run web --image=nginx
kubectl get pods


# deploy a pod on node01 as per specifiction: name: web-pod | container-name: web | image: nginx   (there will be problems here related to cluster)
kubectl run web-pod --image=nginx --dry-run=client -o yaml > pod.yaml
vi pod.yaml # chage the container name
kubectl apply -f pod.yaml
kubectl get pods # we can see pods is in pending state
kubectl get nodes # node01 is NOT ready
ssh node01
systemctl status kubelet
systemctl start kubelet  # ExecStart=/usr/bin/local/kubelet   => normally kubelet exec file should NOT be in local folder
ls /usr/bin/local/kubelet   # does not exist
vi /etc/systemd/system/kubelet.service.d/
# edit this line
ExecStart=/usr/bin/kubelet
systemctl daemon-reload
systemctl start kubelet


# mark the worker node named kworker and unschedulable and reschedule all the pods running on it
kubectl get pods -o wide # check if any pod is scheduled on kworker node
kubectl get nodes
kubectl drain kworker --ignore-daemonsets  # error due to using local volume
kubectl drain kworker --ignore-daemonsets --delete-emptydir-data
kubectl get pods -o wide


# list all persistent volumes sorted by capacity, saving the full kubectl output to /opt/pv/pv_list.txt
kubectl get pv --sort-by=.spec.capacity.storage > /opt/pv/pv_list.txt


# Create a new NetworkPolicy named allow-port-from-namespace in the existing namespace fubar. Ensure that the new NetworkPolicy allows Pods in namespace internal to connect to port 9000 of Pods in namespace fubar.
# Further ensure that the new NetworkPolicy: does not allow access to Pods, which don't listen on port 9000, does not allow access from Pods, which are not in namespace internal => this happens by default if we have specific ingress policy
# apiVersion: networking.k8s.io/v1
# kind: NetwrokPolicy
# metadata:
#   name: named allow-port-from-namespace
#   namespace: fubar
# spec:
#   podSelector: {}
#   policyTypes:
#   - Ingress
#   ingress:
#   - from:
#     - namespaceSelector:
#       matchLabels:
#         kubernetes.io/metadaata.name: internal
#     ports:
#     - protocol: TCP
#       port: 9000


# Reconfigure the existing deployment front-end and add a port specification named http exposing port 80/tep of the existing container nginx.
# Create a new service named front-end-svc exposing the container port http.
# Configure the new service to also expose the individual Pods via a NodePort on the nodes on which they are scheduled. => by default pods are exposed on same node if svc type is NodePort
kubectl congfig use-context k8s
kubectl get deployments
kubectl edit deployment front-end
# spec:
#   containers:
#   - image: nginx:1.14.2
#     imagePullPolicy: IfNotPresent
#     name: nginx
#     # add here
#     ports:
#     - containerPort: 80
#       protocol: TCP 
#       name: http     

kubectl expose deployment front-end --name=front-end-svc --port=80 --type=NodePort --protocol=TCP
kubectl describe svc front-end-svc
curl ENDPOINT-IP:80


# create a depployment named presentation with image nginx
# scale the existing deployment presentation to 3 pods
kubectl create deploy presentation --image=nginx --dry-run=client -o yaml > deploy.yaml
kubectl apply -f deploy.yaml
k scale deploy presentation --replicas=3
k get deploy


# schedule a pod name: kucc8, consul  | app's containers: 2 | containers: nginx
k run kucc8 --image=nginx --dry-run=client -o yaml > app2.yaml
vi app2.yaml
apiVersion: v1
kind: Pod
metadata:
  name: kucc8
  labels:
    run: kucc8
spec:
  containers:
  - image: nginx
    name: nginx
  - image: hashicorp/consul:latest
    name: consul

k apply -f app2.yaml


# Create a persistent volume with name app-data, of capacity 2Gi and access mode ReadOnlyMany. The type of volume is hostPath and its location is /srv/app-data. 
vi app-data.yaml

# apiVersion: v1
# kind: PersistentVolume
# metadata: 
#   name: app-data
# spec:
#   capacity:
#     storage: 2Gi
#   accessModes:
#   - ReadOnlyMany
#   hostPath:
#     path: "/srv/app-data"

k apply -f app-data.yaml
k get pv


# An existing Pod needs to be integrated into the Kubernetes built-in logging architecture (e.g. kubectl logs). Adding a streaming sidecar container is a good and common way to 
# accomplish this requirement. Add a sidecar container named sidecar, using the busybox image, to the existing Pod big-corp-app. The new sidecar container has to run the following command:
# /bin/sh -c "tail -n+1 -f /var/log/big-corp-app.log"
# Use a Volume, mounted at /var/log, to make the log file big-corp-app.log available to the sidecar container.
vi side-pod.yaml

# apiVersion: v1
# kind: Pod
# metadata: 
#   name: big-corp-app
# spec:
#   containers:
#   - name: count
#     image: busybox:1.28
#     args:
#     - /bin/sh
#     - -c
#     - > 
#       i=0;
#       while true;
#       do
#       echo "$i: $(date)" >> /var/log/big-corp-app.log;
#       i=$((i+1));
#       sleep 1;
#       done
#     volumeMounts:
#     - name: varlog
#       mountPath: /var/log
#   - name: sidecar
#     image: busybox
#     args: [/bin/sh, -c, 'tail -n+1 -f /var/log/big-corp-app.log']
#     volumeMounts:
#     - name: varlog
#       mountPath: /var/log
#   volumes:
#   - name: varlog
#     emptyDir: {}

kubectl apply -f side-pod.yaml
kubectl logs big-corp-app -c sidecar


# Create a new PersistentVolumeClaim: 
# Name: pv-volume | Class: csi-hostpath-sc | Capacity: 10Mi
# Create a new Pod which mounts the PersistentVolumeClaim as a volume: Name: web-server, Image: nginx, Mount path: /usr/share/nginx/html, ReadWriteOnce access on the volume.
# using kubectl edit or kubectl patch expand the PersistentVolumeClaim to a capacity of 70Mi and record that change.

# apiVersion: v1
# kind: PersistentVolumeClaim
# metadata:
#   name: pv-volume
# spec:
#   accessModes:
#   - ReadWriteOnce    # ReadWriteOnce access on the volume
#   resources:
#     requests:
#       storage: 10Mi
#   storageClassName: csi-hostpath-sc
k create -f pvc.yaml

# apiVersion: v1
# kind: Pod
# metadata:
#   name: web-server
# spec:
#   containers:
#   - name: web-saerver
#     image: nginx
#     volumeMounts:
#     - mountPath: "/usr/share/nginx/html"
#       name: pv-volume
#   volumes:
#   - name: pv-volume
#     persistentVolumeClaim:
#       claimName: pv-volume
k create -f pod.yaml
k patch pvc pv-volume -p '{"spec":{"resources":{"requests":{"storage":"70Mi"}}}}' --record


# create a new "nginx resource": name:pong, namespace:ing-internal, expose service hello on path /hello using service port 5678 => Ingress
k config use-context k8s
k get ns
# in case namespace does not exist
k create ns ing-internal
vi ping.yaml

# apiVersion: networking.k8s.io/v1
# kind: Ingress 
# metadata:
#   name: pong
#   namespace: ing-internal
#   annotations:
#     nginx.ingress.kubernetes.io/rewrite-target: /
# spec:
#   rules:
#   - http:
#       paths:
#       - path: /hello
#         pathType: Prefix
#         backend: 
#           service: 
#             name: hello 
#             port:
#              5678
k apply -f pong.yaml
# or
k create ing pong -n ing-internal --rule="/hello=hello:5678"
k get svc -A # get the ip address
curl -KL Internal-IP/hello


# Create a new NetworkPolicy named allow-port-from-namespace in the existing namespace echo. Ensure that the new NetworkPolicy allows Pods in namespace internal to connect to port 9200/tcp of Pods in namespace echo. 
# ensure that: does not allow access to Pods, which don't listen on port 9200/tcp => applied via adding the port
# does not allow access from Pods, which are not in namespace internal => applied when selecting namespace
k create ns echo
k create ns internal
k label ns internal namespace=internal  # not required
vi np.yaml
# apiVersion: networking.k8s.io/v1
# kind: NetworkPolicy
# metadata:
#   name: allow-port-from-namespace
#   namespace: echo
# spec:
#   podSelector: {}
#   policyType:
#   - Ingress 
#   ingress:
#   - from:
#     - namespaceSelector:
#       matchLabels:
#         kubernetes.io/metadata.name: internal   # or namespace: internal
#     ports:
#     - protocol: TCP
#       port: 9200

k apply -f np.yaml


# create a pod as follows: name: nginx-kusc00401, image: nginx, node-selector: disk=spinning
k get nodes
k label nodes my-node disk=spinning
k run nginx-kusc00401 --image=nginx --dry-run=client -o yaml > nginx.yaml
vi nginx.yaml
# apiVersion: v1
# kind: Pod
# metadata:
#   name: nginx-kusc00401
#   labels:
#     env: test
# spec:
#   containers:
#   - name: nginx-kusc00401
#     image: nginx
#     nodeSelector:
#       disk: spinning

k apply -f nginx.yaml


# scale deployment guestbook to 5 pods
k config use-context k8s
k scale deploy guestbook --replicas=5


# create a new serviceAccount with name "pvviewer", grant this SA access to list all PVs in the cluster by creating correct ClusterRole called "pvviewer-role" and clusterRoleBinding
# called "pvviewer-role-binding"
k creeate serviceaccount pvviewer
k get sa
k create clusterrole pvviewer-role --verb=list --resource=PersistentVolumes
k get cr
k create clusterrolebinding pvviewer-role-binding --cluster-role=pvviewer-role --serviceaccount=pvviewer
k auth can-i list persistentvolumes --as system:serviceaccount:default:pvviewer


# create a deployment called nginx-deploy with image nginx:1.16 and 1 replica. record the version then upgrade the version of image to 1.17 via rolling update and record the change
k create deploy nginx-deploy --image=nginx:1.16 --replicas=1 --dry-run=client -o yaml > deploy.yaml
vi deploy.yaml
# apiVersion: apps/v1
# kind: Deployment 
# metadata: 
#   name: nginx-deploy
#   labels:
#     app: nginx
# spec: 
#   replicas: 1
#   selector:
#     matchLabels:
#       app: nginx
#   template:
#     metadata:
#       labels:
#         app: nginx
#     spec: 
#       containers:
#       - name: nginx
#         image: 1.17 # update this
#         ports:
#         - containerPort: 80
k apply -f deploy.yaml --record # record the version then upgrade the version of image to 1.17
k get deploy
k rollout history deploy nginx-deploy
# or
k set image deployment/nginx-deploy nginx=1.17 --record
k rollout history deploy nginx-deploy
k describe deploy nginx-deploy
# add the annotation message 'Updated nginx image to 1.17'
kubectl annotate deployment nginx-deploy kubernetes.io/change-cause="Updated nginx image to 1.17"


# create a pod called non-root-pod, image: redis:alpine, runAsUser: 1000, fsGroup: 2000
k run non-root-pod --image redis:alpine --dry-run=client -o yaml > po.yaml
vi po.yaml
# apiVersion: v1
# kind: Pod
# metadata:
#   name: non-root-pod
# spec:
#   # applied to all containers in pod
#   securityContext:
#     runAsUser: 1000
#     fsGroup: 2000
#   containers:
#   - name: non-root-pod
#     image: nginx:alpine

k apply -f po.yaml


# create a network policy that denies all ingress (incoming) traffic
# vi policy.yaml
# apiVersion: networking.k8s.io/v1
# kind: NetworkPolicy
# metadata:
#   name: default-deny
# spec:
#   podSelector: {}
#   policyType:
#   - Ingress  # if we do not mention any specific ingress policy , all is denied!

k create -f policy.yaml


# list all pods sorted by timestamp
k get po --sort-by=.metadata.creationTimestamp

# create a redis pod with a non-persistent volume
apiVersion: v1
kind: Pod
metadata:
  name: non-persistent-redis
  namespace: staging
spec:
  containers:
  - name: redis
    image: redis
    volumeMounts:
    - name: cache-control
      mountPath: /data/redis
  volumes:
  - name: cache-control
    emptyDir: {}

k apply -f po.yaml
k get po -n staging


# Create a pod with image nginx called nginx and allow traffic on port 80
k run nginx --image=nginx --restart=Never --port=80  # restart never is to keep the pod running indefinitely

# Create a busybox pod that runs the command "env" and save the output to "envpod" file
k run busybox --image busybox --restart=Never -- env > envpod.yaml

# create a pod with env variable of var1=value1 and check the environment variable inside the pod
k run nginx --image nginx --restart=Never --env=var1=value1
k exec -it nginx -- env
# or
k describe po nginx | grep value1

# crate a pod that echo's hello world and does not restart and have it deleted when it completes
k run busybox --image busybox -it --rm --restart=Never -- /bin/sh -c 'echo hello world'
k get po 

# create a busybox pod and add a "sleep 3600" command
k run busybox --image=busybox --restart=Never -- /bin/sh -c 'sleep 3600'

# list the nginx pod with custom columns POD_NAME and POD_STATUS
k get po -o=custom-columns="POD_NAME:.metadata.name,POD_STATUS:.status.containerStatuses[].state"

# create apod named nginxpod with image nginx and label env=prod in production namespace
k get ns
k run nginxpod --image nginx --labels=env=prod -n production
k get po -n production --show-labels


# Ensure a single instance of pod nginx is running on each node of the Kubernetes cluster where nginx also represents the Image name which has to be used. Do not override any taints 
# currently in place. => Use DaemonSet to complete this task and use ds-kusc00201 as DaemonSet name.
vi ds.yaml
# apiVersion: apps/v1
# kind: DaemonSet
# metadata:
#   name: ds-kusc00201
#   namespace: kube-system
# spec:
#   selector:
#     matchLabels:
#       app: nginx
#   template:
#     metadata:
#       labels:
#         app: nginx
#     spec: 
#       # this toleration basically overrides the taint of not running on master node
#       tolerations:
#       - key: node-role.kubernetes.io/master
#         effect: NoSchedule
#       containers:
#       - name: nginx
#         image: nginx

k apply -f ds.yaml


# create an static pod named "static-pod" on the "node01" node that uses the "busybox" image and the command "sleep 2000"
k get nodes
k run static-pod --image busybox --dry-run=client -o yaml --command -- sleep 2000 > spod.yaml
cp spod.yaml /etc/kubernetes/manifests


# create a new pod called "super-pod" with image "busybox:1.28" and allow the pod to be able to set "SYS_TIME". the container should sleep for 4800 seconds
k run super-pod --image busybox:1.28 --dry-run=client -o yaml --command -- sleep 4800 > pod.yaml
vi pod.yaml

# apiVersion: v1
# kind: Pod
# metadata:
#   name: super-pod
#   labels:
#     run: super-pod
# spec:
#   #  allow the pod to be able to 
#   securityContext:
#     capabilities:
#       add: ["SYS_TIME"]
#   containers:
#   - name: super-pod
#     image: busybox:1.28
#     command:
#     - sleep
#     - "4800"

k apply -f pod.yaml


# use namespace project-1 for following. create DaemonSet named "daemon-imp" with image "httpd:2.4-alpine" and labels "id=daemon-imp" and "uuid=184". its pods should request 20 millicore
# cpu and 20 mebabytes memory. the pods of the daemonset should run on ALL Nodes, including controlplanes
k get nodes
k get ns
k create ns project-1

# apiVersion: v1
# kind: DaemonSet
# metadata:
#   name: daemon-imp
#   namespace: project-1
#   labels:
#     id: daemon-imp
#     uuid: 184
# spec:
#   selector:
#     matchLabels:
#       id: daemon-imp
#       uuid: 184
#   template:
#     metadata: 
#       labels:
#         id: daemon-imp
#         uuid: 184
#     spec:
#       tolerations:
#       - key: node-role.kubernetes.io/master
#         effect: NoSchedule
#       containers:
#       - image: httpd:2.4-alpine
#         name: daemon-imp
#         resources:
#           requests:
#             memory: "20Mi"
#             cpu: "20m"

k apply -f ds.yaml
k get ds -n project1 -o wide


# create a new serviceAccount "gitops" in namespace "project-1" create role and rolebinding both named "gitops-role" and "gitops-rolebinding". allows the SA 
# to create secrets and configmaps in the namespace
k create serviceaccount gitops -n project-1
k create role gitops-role -n project-1 --verb=create --resources=secrets,configmpas
k create rolebinding gitops-rolebinding -n project-1 --role=gitops-role --serviceaccount=project-1:gitops


# create a pod "web-pod" using image "nginx" with a limit 0.5cpu and 200Mi memory and resource request of 0.1 cpu and 100 mi memory in develop namespace
k run web-pod -n develop --dry-run=client -o yaml > pod.yaml
# vi pod.yaml
# apiVersion: v1
# kind: Pod
# metadata:
#   name: web-pod
#   namespace: develop
# spec:
#   containers:
#   - image: nginx
#     name: nginx
#     resources:
#       requests:
#         cpu: "100m"
#         memory: "100Mi"
#       limits:
#         cpu: "500m"
#         memory: "200Mi"

k apply -f pod.yaml
k get po -n develop

# you have a cluster with pods in many namespaces. "db pods" in project-a namespace should only be acceesible from "service pods" that are running in project-b namespace => create networkPolicy
k get po -n project-a --show-labels
k get po -n project-b --show-labels
vi np.yaml
# apiVersion: networking.k8s.io/v1
# kind: NetworkPolicy
# metadata:
#   name: allow-service-to-db
#   namespace: project-a
#   spec:
#     podSelector:
#       matchLabels:
#         app: db # Assuming your db pods have a label "app=db"
#     PolicyTypes:
#       - Ingress
#     ingress:
#       - from:
#           - namespaceSelector:
#             matchLabels:
#               name: project-b  # Allow access from project-b namespace
#           - podSelector:
#               matchLabels:
#                 app: service  # Allow access from pods with label app=service in project-b namespace

apply -f np.yaml

# create a new pv called web-pv with capacity 2Gi, accessMode ReadWriteOnce, hostPath /vol/data and no storageclass
# create a pvc in ns production named web-pvc. it requests 2Gi storage, accessMode ReadWriteOnce and no storageclass. should be bound to web-pv.
# create a deployment in production namespace called web-deploy that mounts volume at /tmp/web-data, it's pods have image nginx:1.14.2 and it has 3 replicas


# find pods with label app=mysql that are executing high cpu workloads and write name of pod consuming the most cpu to file /opt/toppods.yaml
k top pods -l app=mysql --sort-by=cpu
echo 'mysql-deployment-77fgf-345' >> /opt/toppods.yaml
cat /opt/toppods.yaml


#########################################################
### take the backup of the ETCD at the location "/opt/etcd-backup.db" on the "controlplane" node
export ETCDCTL_API=3
etcdctl snapshot save --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key --endpoint=127.0.0.1:2379 /opt/etcd-backup.db


### a kubeconfig file called "admin.kubeconfig" has been created in /root/CKA . there is something wrong with the configuration. troubleshoot and fix it
# make sure the port for kube-apiserver is correct. correct port number is "6443"
kubectl cluster-info --kubeconfig /root/CKA/admin.kubeconfig


### print name of all deployments in admin2406 namespace
# order: <deployment-name> <container-image> <readt-replica-count> <namespace>
kubectl -n admin2406 get deployment -o custom-columns=DEPLOYMENT:.metadata.name, \
                                       CONTAINER_IMAGE:.spec.template.spec.containers[*].image, \
                                       READY_REPLICAS: .status.readyReplicas, \
                                       NAMESPACE: .metadata.namespace \
                                       --sort-by=.metadata.name > /opt/admin2406_data


### A new deployment called 'alpha-mysql' has been deployed in the 'alpha' namespace. However, the pods are not running. Troubleshoot and fix the issue. The deployment should make use of the 
# persistent volume 'alpha-pv' to be mounted at /'var/lib/mysql' and should use the environment variable 'MYSQL_ALLOW_EMPTY_PASSWORD=1' to make use of an empty root password. Do NOT alter the persistent volume.
kubectl describe alpha-mysql -n alpha  # its correct
kubectl describe pv alpha-pv # its correct
kubectl get pvc -n alpha # we have no pvc to bound the pv to deployment, create it in the namespace
vi pvc-alpha.yaml
# apiVersion: v1
# kind: PersistentVolumeClaim 
# metadata:
#   name: mysql-alpha-pvc
#   namespace: alpha # same ns as the deployment
# spec:
#   accessModes: # should be same as the one on pv
#   - ReadWriteOnce
#   resources:
#     requests:
#       storage: 1Gi #same or smaller than pv
#   storageClassName: slow # same class as pv

kubectl apply -f pvc-alpha.yaml
kubectl get deployment -n alpha
kubectl get pv


### Create a pod called 'secret-1401' in the 'admin1401' namespace using the 'busybox' image. The container within the pod should be called 'secret-admin' and should 'sleep' for '4800' seconds.
# The container should mount a 'read-only secret volume' called 'secret-volume' at the path '/etc/secret-volume'. The secret being mounted has already been created for you and is called 'dotfile-secret'
kubectl run secret-1401 -n admin1401 --image=busybox --dry-run=client -o yaml --command -- sleep 4800 > admin.yaml
vi admin.yaml
# apiVersion: v1
# kind: Pod
# metadata:
#   name: secret-1401
#   namespace: admin1401
#   labels:
#     run: secret-1401
# spec:
#   volumes:
#   - name: secret-volume
#     secret:
#       secretName: dotfile-secret
#   containers:
#   - name: secret-admin
#     image: busybox
#     command:
#     - sleep
#     - "4800"
#     volumeMounts:
#     - name: secret-volume
#       readOnly: true
#       mountPath: "/etc/secret-volume"

kubectl apply -f admin.yaml
