#################################################################################### Upgrade Cluster
# Given an existing Kubernetes cluster running version 1.22.1, upgrade all of the Kubernetes control plane and node components on the master node only to version 1.22.2.
# Be sure to drain the master node before upgrading it and uncordon it after the upgrade
# You are also expected to upgrade kubelet and kubectl on the master node, do NOT upgrade the worker nodes, etcd, the containerv manager, the CNI plugins or the DNS service
# You are also expected to upgrade kubelet and kubectl on the master node.

k cordon mk8s-master-0
k drain mk8s-master-0 --ignore-daemonsets
k get nodes  # make sure its drained and unschedulable
ssh mk8s-master-0
sudo -s
# start the upgrade process
apt update
apt-cache madison kubeadm | grep "1.30" # display detailed information about a specific package available in the APT package repository on Debian-based systems, showing it's different versions | find correct version
apt-mark unhold kubeadm  # when you are ready to upgrade kubeadm to newer versions manually, you can unlock the old, basically un-freezing package version
apt-get install -y kubeadm='1.32.x-*' # -y flag => automatically answer "yes" to any prompts that might appear during the installation process, allowing running the command from a script
kubeadm version -o short
apt-mark hold kubeadm # o prevent the specified packages (kubeadm here) from being automatically upgraded when you run system updates, freezes package version
kubeadm upgrade plan
kubeadm upgrade apply v1.32.x --etcd-upgrade=false --skip-phases=addon/coredns
# upgrade kubectl and kubelet on master node
apt-mark unhold kubelet kubectl 
apt-get update
apt-get install -y kubelet='1.32.x-*' kubectl='1.32.x-*'
kubectl version 
kubelet --version
apt-mark hold kubelet kubectl
systemctl daemon-reload
systemctl restart kubelet
exit
k uncordon mk8s-master-0
k get nodes

# worker-node3 is running an earlier version of the Kubernetes software. Perform an upgrade on worker-node3 and ensure that it is running the exact same version as used on 
# the control-plane and other worker nodes (those nodes are already upgraded)
# upgrading worker node is EXACTLY same as the controlplane, except the "kubeadm upgrade plan" and "kubeadm upgrade apply" we use "kubeadm upgrade node"
ssh controlplane 
kubeadm --version 
k cordon worker-node-3
k drain worker-node-3 --ignore-daemonsets
k get nodes
ssh worker-node-3
sudo -s
# start the upgrade process
apt update
apt-cache madison kubeadm | grep "1.30"
apt-mark unhold kubeadm
apt-get install -y kubeadm="1.30.1-1.1"
kubeadm version -o short
apt-mark hold kubeadm
kubeadm upgrade node  # only change is here
apt-mark unhold kubelet kubectl 
# you CAN NOT check the node version here, do it at end on controlplane node
apt-get update
apt-get install -y kubectl="1.30.1-1.1" kubelet="1.30.1-1.1"
k version 
kubelet --version
apt-mark hold kubectl kubelet
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
sudo -s
kubeadm join 172.30.1.2:6443 --token sfbhsu.llclabbyggkogg9q --discovery-token-ca-cert-hash sha256:4382fe27b4d9a6e4115fb22fb315f4687e355909e76e66ee46a6bde485877464
# if there is any error here check the kubelet
  systemctl status kubelet
  systemctl start kubelet
  systemctl status kubelet  
exit
ssh controlplane
k get nodes
# just for testing
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
ls /var/lib/backup/etcd-snapshot.db  # file should be visible

# restore an existing, previous snapshot located at /var/lib/backup/etcd-snapshot-previous.db

# make sure that etcd user owns it otherwise you need to become a root user and change owner permission then you need to restore db backup
ls -la /var/lib/backup/etcd-snapshot-previous.db
ETCDCTL_API=3 etcdctl snapshot restore /var/lib/backup/etcd-snapshot-previous.db --data-dir=/var/lib/new-etcd/ 
ls /var/lib/new-etcd/
# we need to change the hostPath for the etcd-data volume to the restored database address:
vi /etc/kubernetes/manifests/etcd.yaml
    volumes:
    - hostPath:
          path: /var/lib/new-etcd/
          type: DirectoryOrCreate
      name: etcd-data
# takes around 3 minutes to re-start the etcd pod, during this time the kubectl can't be accessed!
k get po -n kube-system
    
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

# associate a serviceAccount with a deployment
k set serviceaccount deploy/web-dashboard dashboard-sa

# Using kubeadm, read out the expiration date of the apiserver certificate and write it into /root/apiserver-expiration
kubeadm certs check-expiration | grep apiserver
echo "Dec 06, 2025 09:13 UTC" > /root/apiserver-expiration

#  Using kubeadm, renew the certificates of the apiserver and scheduler.conf
kubeadm certs renew apiserver
kubeadm certs renew scheduler.conf

#################################################################################### Cluster Troubleshooting

# kubelet configuration file is usaully located at one of these locations:
# 1. /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
# 2. /etc/systemd/system/kubelet.service or /usr/lib/systemd/system/kubelet.service
# 3. /etc/default/kubelet or etc/sysconfig/kubelet
# 4. /var/lib/kubelet/config.yaml => this is the kubeconfig for kubele

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

# Create a nginx pod called nginx-resolver using image nginx, expose it internally with a service called nginx-resolver-service. Test that you are able to look up 
# the service and pod names from within the cluster. Use the image: busybox: 1.28 for dns lookup. Record results in /root/KA/nginx.svc and /root/CKA/nginx.pod
k run nginx-resolver --image=nginx
k expose po ngnix-resolver --name=nginx-resolver-service --port=80
k describe svc nginx-resolver-service # find its IP address
k get po nginx-resolver -o wide # get it's ip address
# only way to get logs from the pod to outside is run it in background, then exec to it and export results to some file
k run busybox --image busybox:1.28 -- sleep 4800
# since we are all on same namespace it can also be only : nginx-resolver-service
k exec busybox -- nslookup nginx-resolver-service.default.svc.cluster.local > /root/KA/nginx.svc
k exec busybox -- nslookup 10-244-192-2.default.pod.cluster.local > /root/CKA/nginx.pod
# https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#a-aaaa-records-1

# Taint the worker node node01 to be Unschedulable. Once done, create a pod called dev-redis, image redis:alpine, to ensure workloads are not scheduled to this worker node. 
# Finally, create a new pod called prod-redis and image: redis:alpine with toleration to be scheduled on node01.
# key: env_type, value: production, operator: Equal and effect: NoSchedule
k taint nodes node01 env_type=production:NoSchedule
k run dev-redis -image=redis:alpine
k get po -o wide  # scheduled on another node
k run prod-redis -image=redis:alpine --dry-run=client -o yaml > po4. yaml
apiVersion: v1
kind: Pod
metadata:
    labels:
        run: prod-redis
    name: prod-redis
spec:
    containers:
    - image: redis:alpine
      name: prod-redis
    tolerations:
    - key: "env_type"
      operator: "Equal"
      value: "production"
      effect: "NoSchedule"

# access the kubernetes resources via an specific KubeConfig
k get nodes --kubeconfig=/root/CKA/super.kubeconfig  # if there is an error, you will see it here

# if there is a problem with kube-apiserver
k get po -n kube-system   # The connection to the server 172.30.1.2:6443 was refused - did you specify the right host or port? , you won't get kubectl access
journalctl -u kubelet -n 20  # you should see errors related to pods
# you can check logs for all the pods here
ls /var/log/pods
# for example
cat /var/log/pods/kube-system_kube-apiserver-controlplane_36b3bac598f6bd76f4b97286d2bcb99b/kube-apiserver/5.log
# you can check logs for all the containers here
ls /var/log/containers
# for example
cat /var/log/containers/kube-apiserver-controlplane_kube-system_kube-apiserver-0fe767a310f5188065e2be5d5c25f9feef4a52938a5137f6427e371e5da7849c.log
# fix it here
/etc/kubernetes/manifests/kube-apiserver.yaml
systemctl daemon-reload

# accessing all containers when kube-apiserver is down 
crictl ps
# accessing all container logs when kube-apiserver is down 
crictl logs <CONTAIMER-ID>

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

#################################################################################### Static Pods
# create an static pod named "static-pod" on the "node01" node that uses the "busybox" image and the command "sleep 2000"
k get nodes
ssh node01
k run static-pod --image=busybox --dry-run=client -o yaml --command -- sleep 2000 > spod.yaml
cp spod.yaml /etc/kubernetes/manifests/
# or
k run static-busybox --image=busybox --dry-run=client -o yaml --command -- sleep 2000 > /etc/kubernetes/manifests/pod.yaml

# Create a kubectl command that lists out all static pod names currently running within the cluster. Run the kubectl command and save the output directly into 
# the following file /home/ubuntu/static-pods/report.txt on the bastion node.
k get po -A
# if a pod's own references has kind "NODE" it means that its static pod
k get po -A -o=custom-columns=NAME:.metadata.name,STATIC:.metadata.ownReferences[*].kind | grep NODE
vi /home/ubuntu/static-pods/report.txt   # write the names here

apiVersion: v1
kind: Pod
metadata:
  annotations:
    cni.projectcalico.org/podIP: 192.168.203.136/32
  name: blah-01-ip-10-0-0-10.us-west-2.compute.internal
  ownerReferences:
  - apiVersion: v1
    kind: Node

# move static pod from one node to another
ssh controlplane
scp /etc/kubernetes/manifests/my-sp.yaml node01:/etc/kubernetes/manifests/my-sp.yaml
