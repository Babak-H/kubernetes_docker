#################################################################################### Upgrade Cluster
# Given an existing Kubernetes cluster running version 1.22.1, upgrade all of the Kubernetes control plane and node components on the master node only to version 1.22.2.
# Be sure to drain the master node before upgrading it and uncordon it after the upgrade
# You are also expected to upgrade kubelet and kubectl on the master node, do NOT upgrade the worker nodes, etcd, the containerv manager, the CNI plugins or the DNS service
# You are also expected to upgrade kubelet and kubectl on the master node.

k config use-context mk8s
k cordon mk8s-master-0
k drain mk8s-master-0 --ignore-daemonsets
k get nodes  # make sure its drained and unschedulable
ssh mk8s-master-0
sudo -i
# start the upgrade process
apt-mark unhold kubeadm  # unlock the version
apt-get update 
apt-cache show kubeadm | grep 1.30  # find correct version
apt-get install -y kubeadm='1.32.x-*'
sudo apt-mark hold kubeadm # lock the version again
kubeadm version
kubeadm upgrade plan
kubeadm upgrade apply v1.32.x --etcd-upgrade=false --skip-phases=addon/coredns
# upgrade kubectl and kubelet on master node
apt-mark unhold kubelet kubectl 
apt-get update && sudo apt-get install -y kubelet='1.32.x-*' kubectl='1.32.x-*'
apt-mark hold kubelet kubectl
k version 
kubelet --version
systemctl daemon-reload
systemctl restart kubelet
exit
k uncordon mk8s-master-0
k get nodes

# worker-node3 is running an earlier version of the Kubernetes software. Perform an upgrade on worker-node3 and ensure that it is running the exact same version as used on 
# the control-plane and other worker nodes (those nodes are already upgraded)
k get nodes -o wide
ssh controlplane 
kubeadm --version 
k cordon worker-node-3
k drain worker-node-3 --ignore-daemonsets
k get nodes
ssh worker-node-3
sudo -i
# start the upgrade process
apt-mark unhold kubeadm
apt-cache show kubeadm | grep 1.30
apt-get install -y kubeadm=1.30.1-1.1
apt-mark hold kubeadm
kubeadm version -o short
kubeadm upgrade node     # kubeadm upgrade apply v1.32.x => difference with master node, Also calling kubeadm upgrade plan and upgrading the CNI provider plugin is no longer needed
# upgrade kubelet and kubectl on worker node
apt-get update
apt-mark unhold kubectl kubelet
apt-get install -y kubectl=1.30.1-1.1 kubelet=1.30.1-1.1
apt-mark hold kubectl kubelet
k version 
kubelet --version
systemctl daemon-reload
systemctl restart kubelet
exit
k uncordon worker-node-3
k get nodes

#################################################################################### Join Node to cluster
# join node01 worker node to cluster and you have to deploy pod on the node01, pod name should be web and image should be nginx

k get nodes
ssh controlplane # in case we are not on master node
kubeadm token create --print-join-command  # save the output command and use it on node01
ssh node01
sudo -i
kubeadm join 172.30.1.2:6443 --token sfbhsu.llclabbyggkogg9q --discovery-token-ca-cert-hash sha256:4382fe27b4d9a6e4115fb22fb315f4687e355909e76e66ee46a6bde485877464
# if there is any error here check the kubelet
systemctl status kubelet
systemctl start kubelet
systemctl status kubelet
exit
ssh controlplane
k get nodes
k run web --image=nginx
k get po

#################################################################################### ETCD Backup Restore
# create a snapshot of the existing etcd instance running at https://127.0.0.1:2379, saving the snapshot to /var/lib/backup/etcd-snapshot.db
# ca certificate => /opt/kuin/ca.crt   client-certificate => /opt/kuin/etcd-client.crt  client-key => /opt/kuin/etcd-client.key

ssh controlplane
k get po -n kube-system # make sure there is a pod related to etcd here, it means that it is on this node
sudo -i  # backup can only be performed when you are root user
cat /etc/kubernetes/manifests/etcd.yaml  # find the folder with etcd certificates
ls -la /etc/kubernetes/pki/etcd
# --endpoints 127.0.0.1:2379  => since we are on same node this is NOT required here
ETCDCTL_API=3 etcdctl --endpoints 127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save /var/lib/backup/etcd-snapshot.db

# restore an existing, previous snapshot located at /var/lib/backup/etcd-snapshot-previous.db
ls /var/lib
mkdir -p /var/lib/new-etcd
# make sure that etcd user owns it otherwise you need to become a root user and change owner permission then you need to restore db backup
ls -la /var/lib/backup/etcd-snapshot-previous.db
ETCDCTL_API=3 etcdctl snapshot restore --data-dir=/var/lib/new-etcd/ /var/lib/backup/etcd-snapshot-previous.db
vi /etc/kubernetes/manifests/etcd.yaml
    # - hostPath:
    #    path: /var/lib/new-etcd/
    #    type: DirectoryOrCreate
    #   name: etcd-data
    
# take the backup of the ETCD at the location "/opt/etcd-backup.db" on the "controlplane" node
export ETCDCTL_API=3
etcdctl snapshot save --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key --endpoint=127.0.0.1:2379 /opt/etcd-backup.db

#################################################################################### Certificates and Users
# analyze and document all X509 certificates currently being used within the provided cluster using just the kubeadm tool
# update and renew the expiry date within the TLS certificate used by the Kubernetes API server
ssh controlplane
sudo -i
kubeadm certs check-expiration
# CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
# admin.conf                 Jun 26, 2025 14:36 UTC   191d            ca                      no      
# apiserver                  Jun 26, 2025 14:36 UTC   191d            ca                      no      
# apiserver-etcd-client      Jun 26, 2025 14:36 UTC   191d            etcd-ca                 no      
# apiserver-kubelet-client   Jun 26, 2025 14:36 UTC   191d            ca                      no  

# Now renew the API server certificate:
kubeadm certs renew apiserver
    # Certificate:
    #     Data:
    #         Validity
    #             Not Before: Jun 26 14:31:52 2024 GMT
    #             Not After : Dec 16 18:06:55 2025 GMT
    #         Subject: CN = kube-apiserver


# make sure the renew process has applied correctly
echo | openssl s_client -connect 10.0.0.100:6443 2>/dev/null | openssl x509 -text


# Create a new user called john. Grant him access to the cluster. John should have permission to create, list, get, update and delete pods in the development namespace. 
# The private key exists in the location: /root/CKA/john.key and csr at /root/CKA/john.csr.
# https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#create-certificatessigningrequest

cat /root/CKA/john.csr | base64 | tr -d "\n"  # copy the encrypted value value
# create the certificate signing request file and apply it
    apiVersion: certificates.k8s.io/v1
    kind: CertificateSigningRequest
    metadata:
        name: john
    spec:
        request: ...
        signerName: https://kubernetes.io/kube-apiserver-client
        usage: 
        - client auth 
        
k create -f csr.yaml
k get csr # john should be pending
k certificate approve john
k get csr # john should be approved

k create role developer -verb=create,list,get,update,delete —resource=pods -n development
k create rolebinding dev-john-role --role=developer --user=john -n development  # bound Role developer to user john
k auth can-i get pods --as=john -n development

#################################################################################### Cluster Troubleshooting

# kubelet configuration file is usaully located at one of these locations:
# 1. /var/lib/kubelet/config.yaml
# 2. /etc/systemd/system/kubelet.service or /usr/lib/systemd/system/kubelet.service
# 3. /etc/default/kubelet or etc/sysconfig/kubelet

# a kubeconfig file called "admin.kubeconfig" has been created in /root/CKA . there is something wrong with the configuration. troubleshoot and fix it
# make sure the port for kube-apiserver is correct. correct port number is "6443"
k cluster-info --kubeconfig=/root/CKA/admin.kubeconfig
vi /root/CKA/admin.kubeconfig  # change the kube-apiserver port to 6443

# A Kubernetes worker node, named wk8s-node-0 is in state NotReady. Investigate why this is the case, and perform any appropriate steps to bring the node to a Ready state, 
# ensuring that any changes are made permanent
k config use-context wk8s 
k get nodes 
k describe nodes wk8s-node-0    # kubelet stopped sending status, Node status unknown
ssh wk8s-node-0 
sudo -i 
# first step when kubelet stopped working is to restart it
systemctl enable --now kubelet 
systemctl restart kubelet
# or
systemctl start kubelet
systemctl status kubelet 
exit
kubectl get nodes 

# deploy a pod on node01 as per specifiction: name: web-pod | container-name: web | image: nginx   (there will be problems here related to cluster)
k run web-pod --image=nginx --dry-run=client -o yaml > pod.yaml
vi pod.yaml # change the container name
k apply -f pod.yaml
k get pods # we can see pods is in pending state
k get nodes # node01 is NOT ready
ssh node01
systemctl status kubelet
systemctl start kubelet  # ExecStart=/usr/bin/local/kubelet   => normally kubelet exec file should NOT be in local folder
ls /usr/bin/local/kubelet   # does not exist
vi /etc/systemd/system/kubelet.service.d/  # go to folder where kubelet executable is located at
# edit this line
ExecStart=/usr/bin/kubelet
systemctl daemon-reload
systemctl start kubelet

# Set the node named ek8s-node-0 as unavailable and reschedule all the pods running on it.
k get nodes
k cordon ek8s-node-1
k drain ek8s-node-1 --ignore-daemonsets
# if above throws error
k drain ek8s-node-1 --ignore-daemonsets --delete-emptydir-data
# or
kubectl drain ek8s-node-1 --ignore-daemonsets --force
kubectl get nodes

# mark the worker node named kworker and unschedulable and reschedule all the pods running on it
k get pods -o wide # check if any pod is scheduled on kworker node
k get nodes
k drain kworker --ignore-daemonsets  # error due to using local volume
k drain kworker --ignore-daemonsets --delete-emptydir-data
kubectl get pods -o wide

# coreDNS version
k describe po coredns-xxx-xxx -n kube-system # coreDNS version is visible here

# coreDNS TTL?
# The TTL value used for CoreDNS lookup responses is configured within a ConfigMap resource named coredns located in the kube-system namespace. 
k get cm codedns -n kube-system
# kubernetes cluster.local in-addr.arpa ip6.arpa {
#     pods insecure
#     fallthrough in-addr.arpa ip6.arpa
#     ttl 30   ###### 
# }

# Determine whether there are any pods running on the cluster that are not using CoreDNS for DNS resolution ?
k get po -A -o=custom-columns=NodeName:.metadata.name,DNSPOLICY:.spec.dnsPolicy

# Determine the Pod CIDR range used by the cluster.
k get cm kube-proxy -n kube-system -o yaml | grep -i cidr  # 192.168.0.0/16

# Determine the Service CIDR range used by the cluster.
k get po kube-apiserver-xxx-xxx -n kube-system -o yaml | grpe -i "service-cluster-ip-range"  # - --service-cluster-ip-range=10.96.0.0/12

# Determine worker node1's Pod capacity (cluster-node1 - 10.0.0.10)
k describe node node01 | grep pods  # pods: 110

# Determine which CNI provider is currently being used, and how IPAM has been configured for the pod network.
ssh controlplane
sudo -i
ls /opt/cni/bin  # lists all available CNI and installed one
cat /etc/cni/net.d/10-calico.conflist 
# "ipam": {
#     "type": "calico-ipam"

# One of the cluster's worker nodes hasn't yet correctly registered. You need to investigate and fix this issue.
ssh worker-node
systemctl status kubelet
journalctl -u kubelet -n 10  # shows last 10 lines
# error related to address of kubelet
        # kubelet.service: Failed to locate executable /usr/etc/kubelet: No such file or directory
        # kubelet.service: Failed at step EXEC spawning /usr/etc/kubelet: No such file or directory
which kubelet # shows correct address for kubelet
vi /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
# edit this line
ExecStart=/usr/...

systemctl daemon-reload
systemctl start kubelet
systemctl status kubelet



# Taint the worker node to be Unschedulable. Once done, create a pod called dev-redis, image redis:alpine to ensure workloads are not scheduled to this worker node. Finally, 
# create a new pod called prod-redis and image redis:alpine with toleration to be scheduled on node01. 
k get nodes -o wide
k taint node node01 env_type=production:NoSchedule 
k describe nodes node01 | grep -i taint 
k run dev-redis --image=redis:alpine --dry-run=clinet -o yaml > pod-redis.yaml
kubectl apply -f pod-redis.yaml 

    apiVersion: v1 
    kind: Pod 
    metadata:
      name: prod-redis  # edit here
    spec:
      containers:
      - name: prod-redis # edit here 
        image: redis:alpine
      add toleration here
      tolerations:
      - effect: Noschedule 
        key: env_type 
        operator: Equal 
        value: prodcution

kubectl get pods -o wide 


echo journalctl -u kubelet >> /home/ubuntu/kubelet.sh
echo k logs kube-scheduler-ip-10-0-0-100.us-west-2.compute.internal -n kube-system >> /home/ubuntu/scheduler.sh


#################################################################################### custom json values
# Check to see how many nodes are ready (not including nodes tainted NoSchedule) and write the number to /opt/KUSC00402/kusc00402.txt.
echo $(k get nodes --no-headers | grep -v 'NoSchedule' | grep -c 'Ready' | wc -l ) > opt/KUSC00402/kusc00402.txt
# or
k get nodes -o=custom-columns=NodeName:.meta.name,TaintKey:.spec.taints[*].key,TaintValue:.spec.taints[*].value,TaintEffect:.spec.taints[*].effect # then manually add all ready ones to the file 
# .items does not need to be included
k get nodes -o=custom-columns=OSIMAGE:.status.nodeInfo.osImage --no-header > /opt/outputs/os-list.txt

# From the pod label name=overloaded-cpu, find pods running high CPU workloads and write the name of the pod consuming most CPU to the file /opt/KUTR00401/KUTR00401.txt (which already exists)
k top pod -l name=overloaded-cpu --sort-by=cpu 
echo "POD-NAME" >> /opt/KUTR00401/KUTR00401.txt  # >> adds it to the files and empties whatever was inside of it 

# list all persistent volumes sorted by capacity, saving the full kubectl output to /opt/pv/pv_list.txt
k get pv --sort-by=.spec.capacity.storage > /opt/pv/pv_list.txt

# list the nginx pod with custom columns POD_NAME and POD_STATUS
k get po -o=custom-columns="POD_NAME:.metadata.name,POD_STATUS:.status.containerStatuses[].state"

# find pods with label app=mysql that are executing high cpu workloads and write name of pod consuming the most cpu to file /opt/toppods.yaml
k top pods -l app=mysql --sort-by=cpu
echo 'mysql-deployment-77fgf-345' >> /opt/toppods.yaml
cat /opt/toppods.yaml

# print name of all deployments in admin2406 namespace
# order: <deployment-name> <container-image> <readt-replica-count> <namespace>
k -n admin2406 get deploy -o custom-columns=DEPLOYMENT:.metadata.name, \
                                       CONTAINER_IMAGE:.spec.template.spec.containers[*].image, \
                                       READY_REPLICAS: .status.readyReplicas, \
                                       NAMESPACE: .metadata.namespace \
                                       --sort-by=.metadata.name > /opt/admin2406_data

# # From the hr pod nslookup the mysql service (in payroll namespace) and redirect the output to a file /root/CKA/nslookup.out
k exec hr -- nslookup mysql.payroll.svc.cluster.local > /root/CKA/nslook.out

# list all pods sorted by timestamp
k get po --sort-by=.metadata.creationTimestamp

# Monitor the logs of pod foo and: Extract log lines corresponding to error file-not-found, Write them to /opt/KUTR00101/foo 
k config use-context k8s
k get pods
k logs foo | grep "error file-not-found" > /opt/KUTR00101/foo

#################################################################################### Role, RoleBinding, ClusterRole, ClusterRoleBinding
# You have been asked to create a new ClusterRole for a deployment pipeline and bind it to a specific ServiceAccount scoped to a specific namespace.
# Create a new ClusterRole named deployment-clusterrole, which only allows to create the following resource types: Deployment, StatefulSet, DaemonSet
# Create a new ServiceAccount named cicd-token in the existing namespace app-team1, Bind the new ClusterRole deployment-clusterrole to the new ServiceAccount cicd-token, limited to the namespace app-team1.
k create clusterrole deployment-clusterrole --verb=create --resource=deployment,statefulset,daemonset -o yaml --dry-run=client | k apply -f -
k create serviceaccount cicd-token -n app-team1
k create clusterrolebinding deployment-clusterrolebinding --clusterrole=deployment-clusterrole --serviceaccount=cicd-token -n app-team1 -o yaml --dry-run=client | kubectl apply -f -
k auth can-i create deployment -n app-team1 --as system:serviceaccount:app-team1:cicd-token # yes
k auth can-i create daemonset -n app-team1 --as=system:serviceaccount # no

# create a new serviceAccount with name "pvviewer", grant this SA access to list all PVs in the cluster by creating correct ClusterRole called "pvviewer-role" 
# and clusterRoleBinding called "pvviewer-role-binding"
k creeate serviceaccount pvviewer
k get sa
k create clusterrole pvviewer-role --verb=list --resource=PersistentVolumes
k get cr
k create clusterrolebinding pvviewer-role-binding --cluster-role=pvviewer-role --serviceaccount=pvviewer
k auth can-i list persistentvolumes --as system:serviceaccount:default:pvviewer  # yes

# create a new serviceAccount "gitops" in namespace "project-1" create role and rolebinding both named "gitops-role" and "gitops-rolebinding". allows the SA 
# to create secrets and configmaps in the namespace
k create serviceaccount gitops -n project-1
k create role gitops-role -n project-1 --verb=create --resources=secrets,configmpas
k create rolebinding gitops-rolebinding -n project-1 --role=gitops-role --serviceaccount=gitops
k auth can-i create secret -n project-1 --as system:serviceaccount:project-1:gitops

#################################################################################### NetworkPolicy
# Create a new NetworkPolicy named allow-port-from-namespace in the existing namespace echo. Ensure that the new NetworkPolicy allows Pods in namespace internal to connect to port 9200/tcp of Pods in namespace echo. 
# ensure that: does not allow access to Pods, which don't listen on port 9200/tcp => applied via adding the port
# does not allow access from Pods, which are not in namespace internal => applied when selecting namespace
k create ns echo
k create ns internal
k label ns internal namespace=internal  # not required

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-port-from-namespace
  namespace: echo
spec:
  podSelector: {}
  policyTypes:
  - Ingress 
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: internal   # or namespace: internal
    ports:
    - protocol: TCP
      port: 9200


# create a network policy that denies all ingress (incoming) traffic

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes:
  - Ingress  # if we do not mention any specific ingress policy , all is denied!

# you have a cluster with pods in many namespaces. "db" pods in "project-a" namespace should only be acceesible from "service" pods that are running in "project-b" namespace => create networkPolicy
k get po -n project-a --show-labels
k get po -n project-b --show-labels

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-service-to-db
  namespace: project-a
spec:
  podSelector:
    matchLabels:
      app: db  # Assuming your db pods have a label "app=db"
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: project-b  # Allow access from project-b namespace
    - podSelector:
         matchLabels:
           app: service  # Allow access from pods with label app=service in project-b namespace

#################################################################################### Ingress
# create a new "nginx resource": name:pong, namespace:ing-internal, expose service hello on path /hello using service port 5678 => Ingress

k config use-context k8s
k get ns
# in case namespace does not exist
k create ns ing-internal
k get svc -n ing-internal

apiVersion: networking.k8s.io/v1
kind: Ingress 
metadata:
  name: pong
  namespace: ing-internal
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /hello
        pathType: Prefix
        backend: 
          service: 
            name: hello 
            port:
             5678
# or
k create ingress pong -n ing-internal --rule="/hello=hello:5678"
k get svc -A # get the ip address
curl -KL Internal-IP/hello

k create ingress web -n ca1 --rule="/=web-svc:80"
kubectl describe cm -n ca1 webapp-host-fqdn
k edit ingress web -n ca1

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
  namespace: ca1
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: web.35.83.124.103.nip.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-svc
                port:
                  number: 80

#################################################################################### DaemonSets
# Ensure a single instance of pod nginx is running on each node of the Kubernetes cluster where nginx also represents the Image name which has to be used. Do not override any taints 
# currently in place. => Use DaemonSet to complete this task and use ds-kusc00201 as DaemonSet name.

apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ds-kusc00201
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec: 
      # this toleration basically overrides the taint of not running on master node
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: nginx
        image: nginx

# use namespace project-1 for following. create DaemonSet named "daemon-imp" with image "httpd:2.4-alpine" and labels "id=daemon-imp" and "uuid=184". its pods should request 20 millicore
# cpu and 20 mebabytes memory. the pods of the daemonset should run on ALL Nodes, including controlplanes
k get nodes
k get ns
k create ns project-1  # in case not existing

apiVersion: v1
kind: DaemonSet
metadata:
  name: daemon-imp
  namespace: project-1
  labels:
    id: daemon-imp
    uuid: 184
spec:
  selector:
    matchLabels:
      id: daemon-imp
      uuid: 184
  template:
    metadata: 
      labels:
        id: daemon-imp
        uuid: 184
    spec:
      tolerations: # the pods of the daemonset should run on ALL Nodes, including controlplanes
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - image: httpd:2.4-alpine
        name: daemon-imp
        resources:
          requests:
            memory: "20Mi"
            cpu: "20m"

k get ds -n project1 -o wide

#################################################################################### PV, PVC, StorageClass
# Create a persistent volume with name app-data, of capacity 2Gi and access mode ReadOnlyMany. The type of volume is hostPath and its location is /srv/app-data. 
apiVersion: v1
kind: PersistentVolume
metadata: 
  name: app-data
spec:
  capacity:
    storage: 2Gi
  accessModes:
  - ReadOnlyMany
  hostPath:
    path: "/srv/app-data"
  storageClassName: gp2

k get pv

# Create a new PersistentVolumeClaim: Name: pv-volume | Class: csi-hostpath-sc | Capacity: 10Mi
# Create a new Pod which mounts the PersistentVolumeClaim as a volume: Name: web-server, Image: nginx, Mount path: /usr/share/nginx/html, ReadWriteOnce access on the volume.
# using kubectl edit or kubectl patch expand the PersistentVolumeClaim to a capacity of 70Mi and record that change.
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pv-volume
spec:
  accessModes:
  - ReadWriteOnce    # ReadWriteOnce access on the volume, so should be same on pvc that chooses it
  resources:
    requests:
      storage: 10Mi
  storageClassName: csi-hostpath-sc

apiVersion: v1
kind: Pod
metadata:
  name: web-server
spec:
  volumes:
  - name: pv-volume
    persistentVolumeClaim:
      claimName: pv-volume
  containers:
  - name: web-server
    image: nginx
    volumeMounts:
    - mountPath: "/usr/share/nginx/html"
      name: pv-volume
      
k patch pvc pv-volume -p '{"spec":{"resources":{"requests":{"storage":"70Mi"}}}}' --record
# or
k edit pvc pv-volume --record

# create a redis pod with a non-persistent volume
apiVersion: v1
kind: Pod
metadata:
  name: non-persistent-redis
  namespace: staging
spec:
  volumes:
  - name: cache-control
    emptyDir: {}
  containers:
  - name: redis
    image: redis
    volumeMounts:
    - name: cache-control
      mountPath: /data/redis
      
k get po -n staging

# create a new pv called web-pv with capacity 2Gi, accessMode ReadWriteOnce, hostPath /vol/data and no storageclass
# create a pvc in ns production named web-pvc. it requests 2Gi storage, accessMode ReadWriteOnce and no storageclass. should be bound to web-pv.
# create a deployment in production namespace called web-deploy that mounts volume at /tmp/web-data, it's pods have image nginx:1.14.2 and it has 3 replicas
apiVersion: v1
kind: PersistentVolume
metadata:
  name: web-pv
spec:
  capacity:
    storage: 2Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain   # default
  hostPath:
    path: /vol/data
  storageClassName: ""
  
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: web-pvc
  namespace: production
spec:
  resources:
    requests:
      storage: 2Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: ""

k create deploy web-deploy --image=nginx:1.14.2 --replicas=3 --dry-run=client -o yaml > deploy.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deploy
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      volumes:
        - name: web-volume
          persistentVolumeClaim: 
            claimName: web-pvc
      containers:
        - name: nginx
          image: nginx:1.14.2
          volumeMounts:
            - mountPath: /tmp/web-data
              name: web-volume

# a new deployment called 'alpha-mysql' has been deployed in the 'alpha' namespace. However, the pods are not running. Troubleshoot and fix the issue. The deployment should make use of the 
# persistent volume 'alpha-pv' to be mounted at /'var/lib/mysql' and should use the environment variable 'MYSQL_ALLOW_EMPTY_PASSWORD=1' to make use of an empty root password. Do NOT alter the persistent volume.
k describe alpha-mysql -n alpha  # its correct
k describe pv alpha-pv # its correct
k get pvc -n alpha # we have no pvc to bound the pv to deployment, create it in the namespace

apiVersion: v1
kind: PersistentVolumeClaim 
metadata:
  name: mysql-alpha-pvc
  namespace: alpha # same ns as the deployment
spec:
  accessModes: # should be same as the one on pv
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi #same or smaller than pv
  storageClassName: slow # same class as pv

kubectl get deployment -n alpha
kubectl get pv

# Create a pod called 'secret-1401' in the 'admin1401' namespace using the 'busybox' image. The container within the pod should be called 'secret-admin' and should sleep for 4800 seconds.
# The container should mount a read-only secret volume called 'secret-volume' at the path '/etc/secret-volume'. The secret being mounted has already been created for you and is called 'dotfile-secret'
k run secret-1401 -n admin1401 --image=busybox --dry-run=client -o yaml --command -- sleep 4800 > admin.yaml

apiVersion: v1
kind: Pod
metadata:
  name: secret-1401
  namespace: admin1401
  labels:
    run: secret-1401
spec:
  volumes:
  - name: secret-volume
    secret:
      secretName: dotfile-secret
  containers:
  - name: secret-admin
    image: busybox
    command:
    - sleep
    - "4800"
    volumeMounts:
    - name: secret-volume
      readOnly: true
      mountPath: "/etc/secret-volume"


apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: class
provisioner: kubernetes.io/aws-ebs
reclaimPolicy: Retain 
allowVolumeExpansion: false
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp2
      
#################################################################################### Service
# Reconfigure the existing deployment front-end and add a port specification named http exposing port 80/tcp of the existing container nginx.
# Create a new service named front-end-svc exposing the container port http.
# Configure the new service to also expose the individual Pods via a NodePort on the nodes on which they are scheduled. => by default pods are exposed on same node if svc type is NodePort
k get deploy
k edit deploy front-end

spec:
  containers:
  - image: nginx:1.14.2
    imagePullPolicy: IfNotPresent
    name: nginx
    # add here
    ports:
    - containerPort: 80
      protocol: TCP 
      name: http     

k expose deploy front-end --name=front-end-svc --port=80 --targetPort=80 --type=NodePort --protocol=TCP
k describe svc front-end-svc  # get ip address of the service here
curl ENDPOINT-IP:80

#################################################################################### Pods

# create an static pod named "static-pod" on the "node01" node that uses the "busybox" image and the command "sleep 2000"
k get nodes
k run static-pod --image busybox --dry-run=client -o yaml --command -- sleep 2000 > spod.yaml
ssh node01
cp spod.yaml /etc/kubernetes/manifests
# or
k run static-busybox --image=busybox --dry-run=client -o yaml --command -- sleep 1000 > /etc/kubernetes/manifests/pod.yaml

# Create a kubectl command that lists out all static pod names currently running within the cluster. Run the kubectl command and save the output directly into 
# the following file /home/ubuntu/static-pods/report.txt on the bastion node.
k get po --all-namespaces
# if a pod's own references has kind "NODE" it means that its static pod
k get po -A -o=custom-columns=NAME:.metadata.name,STATIC:.metadata.ownReferences[*].kind | grep

# apiVersion: v1
# kind: Pod
# metadata:
#   annotations:
#     cni.projectcalico.org/podIP: 192.168.203.136/32
#   name: blah-01-ip-10-0-0-10.us-west-2.compute.internal
#   ownerReferences:
#   - apiVersion: v1
#     kind: Node


# An existing Pod needs to be integrated into the Kubernetes built-in logging architecture (e.g. kubectl logs). Adding a streaming sidecar container is a good and common way to 
# accomplish this requirement. Add a sidecar container named sidecar, using the busybox image, to the existing Pod big-corp-app. The new sidecar container has to run the following command:
# /bin/sh -c "tail -n+1 -f /var/log/big-corp-app.log"
# Use a Volume, mounted at '/var/log', to make the log file 'big-corp-app.log' available to the sidecar container.
apiVersion: v1
kind: Pod
metadata: 
  name: big-corp-app
spec:
  volumes:
  - name: varlog
    emptyDir: {}
  containers:
  - name: count  # original container
    image: busybox:1.28
    args:
    - /bin/sh
    - -c
    - > 
      i=0;
      while true;
      do
      echo "$i: $(date)" >> /var/log/big-corp-app.log;
      i=$((i+1));
      sleep 1;
      done
    volumeMounts:
    - name: varlog
      mountPath: /var/log
  - name: sidecar  # our new sidecar container
    image: busybox
    args: [/bin/sh, -c, 'tail -n+1 -f /var/log/big-corp-app.log']
    volumeMounts:
    - name: varlog
      mountPath: /var/log

k logs big-corp-app -c sidecar

# schedule a pod name: kucc8, consul  | app's containers: 2 | containers: nginx, consul
k run kucc8 --image=nginx --dry-run=client -o yaml > app2.yaml

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

# create a pod as follows: name: nginx-kusc00401, image: nginx, nodeSelector: disk=spinning
k get nodes
k label nodes my-node disk=spinning  # in case the label is NOT added to the node
k run nginx-kusc00401 --image=nginx --dry-run=client -o yaml > nginx.yaml

apiVersion: v1
kind: Pod
metadata:
  name: nginx-kusc00401
  labels:
    env: test
spec:
  containers:
  - name: nginx-kusc00401
    image: nginx
    # add it here:
    nodeSelector:
      disk: spinning

# create a pod called non-root-pod, image: redis:alpine, runAsUser: 1000, fsGroup: 2000
k run non-root-pod --image=redis:alpine --dry-run=client -o yaml > po.yaml

apiVersion: v1
kind: Pod
metadata:
  name: non-root-pod
spec:
  # applied to all containers in pod
  securityContext:
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: non-root-pod
    image: nginx:alpine

# create a new pod called "super-pod" with image "busybox:1.28" and allow the pod to be able to set "SYS_TIME". the container should sleep for 4800 seconds
k run super-pod --image=busybox:1.28 --dry-run=client -o yaml --command -- sleep 4800 > pod.yaml

apiVersion: v1
kind: Pod
metadata:
  name: super-pod
  labels:
    run: super-pod
spec:
  securityContext: #  allow the pod to be able to 
    capabilities:
      add: ["SYS_TIME"]
  containers:
  - name: super-pod
    image: busybox:1.28
    command:
    - sleep
    - "4800"

# create a pod "web-pod" using image "nginx" with a limit 0.5cpu and 200Mi memory and resource request of 0.1 cpu and 100 mi memory in develop namespace
k run web-pod -n develop --dry-run=client -o yaml > pod.yaml

apiVersion: v1
kind: Pod
metadata:
  name: web-pod
  namespace: develop
spec:
  containers:
  - image: nginx
    name: web-pod
    resources:
      requests:
        cpu: "100m"
        memory: "100Mi"
      limits:
        cpu: "500m"
        memory: "200Mi"

k get po -n develop

# Create a pod with image nginx called nginx and allow traffic on port 80
k run nginx --image=nginx --restart=Never --port=80  # restart never is to keep the pod running indefinitely

# Create a busybox pod that runs the command "env" and save the output to "envpod" file
k run busybox --image=busybox --restart=Never -- /bin/sh -c 'env' 
k logs busybox > envpod

# create a pod with env variable of var1=value1 and check the environment variable inside the pod
k run nginx --image nginx --restart=Never --env=var1=value1
k exec nginx -- env
# or
k describe po nginx | grep value1

# crate a pod that echo's hello world and does not restart and have it deleted when it completes
k run busybox --image busybox -it --rm --restart=Never -- /bin/sh -c 'echo hello world'
k get po 

# create a pod named nginxpod with image nginx and label env=prod in production namespace
k get ns
k run nginxpod --image=nginx --labels=env=prod -n production
k get po -n production --show-labels


apiVersion: v1
kind: Pod
metadata:
  labels:
    run: nginx
  name: nginx
  namespace: qq3
spec:
  containers:
  - image: nginx
    name: nginx
    livenessProbe:
      httpGet:
        port: 80
    readinessProbe: 
      httpGet:
        port: 80


apiVersion: v1
kind: Pod
metadata:
  labels:
    run: apache
  name: apache
spec:
  containers:
  - image: httpd
    name: apache
    env:
      - name: CONTENT
        valueFrom:
          configMapKeyRef:
            name: cloudacademy
            key: content
      - name: PASSWORD
        valueFrom:
          secretKeyRef:
            name: credentials
            key: password 
      - name: USERNAME
        valueFrom:
          secretKeyRef:
            name: credentials
            key: username

#################################################################################### Deployment

# create a deployment named 'presentation' with image nginx
# scale the existing deployment presentation to 3 pods
k create deploy presentation --image=nginx --dry-run=client -o yaml | k apply -f -
k scale deploy presentation --replicas=3
k get deploy

# create a deployment called nginx-deploy with image nginx:1.16 and 1 replica. Record the version then upgrade the version of image to 1.17 via rolling update and record the change
k create deploy nginx-deploy --image=nginx:1.16 --replicas=1 --dry-run=client -o yaml > deploy.yaml

apiVersion: apps/v1
kind: Deployment 
metadata: 
  name: nginx-deploy
  labels:
    app: nginx
spec: 
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec: 
      containers:
      - name: nginx
        image: 1.16
        ports:
        - containerPort: 80

k apply -f deploy.yaml --record 
k set image deployment/nginx-deploy nginx=1.17 --record  # or edit it via "k edit deploy nginx-deploy --record"
k rollout history deploy nginx-deploy
k describe deploy nginx-deploy
# add the annotation message 'Updated nginx image to 1.17'
k annotate deploy nginx-deploy kubernetes.io/change-cause="Updated nginx image to 1.17"

kubectl rollout undo deployment/apache-deployment -n qq3
