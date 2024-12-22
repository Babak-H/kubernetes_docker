# what is the range of IP adresses configured for pods on this cluster?
# the ntwrok is configured with weave. check the weave pods logs
k logs weave-net-bk9h7 -n kube-system | grep -i ipalloc
    # Defaulted container "weave" out of: weave, weave-npc, weave-init (init)
    # INFO: 2024/11/26 14:03:24.230278 Command line options: map[conn-limit:200 datapath:datapath db-prefix:/weavedb/weave-net docker-api: expect-npc:true http-addr:127.0.0.1:6784 
    # ipalloc-init:consensus=1 ipalloc-range:10.244.0.0/16 metrics-addr:0.0.0.0:6782 name:b2:c2:ed:7f:e2:78 nickname:node01 no-dns:true no-masq-local:true port:6783]
# ipalloc-range:10.244.0.0/16

# What is the IP Range configured for the services within the cluster?
# inspect the setting on kube-api server
cat /etc/kubernetes/manifests/kube-api-server.yaml | grep cluster-ip-range
#  - --service-cluster-ip-range=10.96.0.0/12

# What type of proxy is the kube-proxy configured to use?
# check the logs of kube-proxy pods
k logs kube-proxy-6x95x -n kube-system
# server_linux.go:66] "Using iptables proxy"
# server.go:677] "Successfully retrieved node IP(s)" IPs=["192.14.41.6"]

# Identify the DNS solution implemented in this cluster.
k get pods -n kube-system | grep dns
# coredns-77d6fd4654-5h89h  1/1   Running   0  2m27s
# coredns-77d6fd4654-mczjv  1/1   Running   0  2m27s

# What is the IP of the CoreDNS server that should be configured on pods to resolve services?
k get svc -n kube-system | grep dns
# kube-dns   ClusterIP   172.20.0.10   <none> 53/UDP,53/TCP,9153/TCP   3m13s

# Where is the configuration file located for configuring the CoreDNS service?
# inspect the args field of the coredns deployment and check the file used
k -n kube-system describe deploy coredns | grep -A2 Args
    # Args:
    #   -conf
    #   /etc/coredns/Corefile
    
# How is the Corefile passed into the CoreDNS pod?
k -n kube-system get cm | grep dns
# coredns  1  7m3s

# Which of the below name CANNOT be used to access the payroll service from the test application?
kubectl get po
# NAME                READY   STATUS    RESTARTS   AGE
# hr                  1/1     Running   0          8m31s
# simple-webapp-1     1/1     Running   0          8m12s
# simple-webapp-122   1/1     Running   0          8m12s
# test                1/1     Running   0          8m31s
kubectl get svc
# NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
# kubernetes     ClusterIP   172.20.0.1       <none>        443/TCP        9m26s
# test-service   NodePort    172.20.90.60     <none>        80:30080/TCP   8m33s
# web-service    ClusterIP   172.20.203.129   <none>        80/TCP         8m34s
kubectl get po -n payroll
# NAME   READY   STATUS    RESTARTS   AGE
# web    1/1     Running   0          8m40s
kubectl get svc -n payroll
# NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
# web-service   ClusterIP   172.20.140.81   <none>        80/TCP    8m48s

# web-service.payroll.svc.cluster.local   can
# web-service.payroll.svc.cluster    CAN'T
# web-service.payroll.svc   can
# web-service.payroll   can

# find all static pods
kubectl get po -A | grep controlplane
kubectl get po -A -o wide | grep controlplane

# do it inside the controlplane
ssh controlplane
ls /etc/kubernetes/manifests

# how to find ipadress of a node?
kubectl get nodes -o wide

# get all events
kubectl get events -o wide

# upgrade a node
kubectl drain node01 --ignore-daemonsets
kubectl uncordon node01
kubectl cordon node01

# upgrade masternode (controlplane)
# we are on controlplane node
cat /etc/*release*
kubectl get nodes
kubectl get nodes -o wide
kubectl describe nodes controlplane
kubeadm version
kubeadm upgrade plan
kubectl drain controlplane --ignore-daemonsets
vim /etc/apt/sources.list.d/kubernetes.list
# deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/1.31.0-1.1/deb/ /
apt update
apt-cache madison kubeadm
apt-get install kubeadm=1.31.0-1.1
kubeadm upgrade plan v1.31.0
kubeadm upgrade apply v1.31.0
apt-get install kubelet=1.31.0-1.1  # some master nodes might not need kubelet
kubectl uncordon controlplane
kubectl get nodes -o wide

# upgrade the worker nodes
kubeadm version
kubectl drain node01 --ignore-daemonsets
kubectl get nodes -o wide
ssh node01
vi /etc/apt/sources.list.d/kubernetes.list
# deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/1.31.0-1.1/deb/ /
apt update
apt-cache madison kubeadm
apt-get install kubeadm=1.31.0-1.1
kubeadm upgrade node
apt-get install kubelet=1.31.0-1.1
systemctl daemon-reload
systemctl restart kubelet
exit
kubectl uncordon node01
kubectl get nodes -o wide

# ETCD
kubectl logs etcd-controlplane -n kube-system | grep -i 'etcd-version'
kubectl describe po etcd-controlplane -n kube-system

# create a ETCD backup (from the etcd machine)
# --endpoints: Optional Flag, points to the address where ETCD is running (127.0.0.1:2379)
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
# --cacert: Mandatory Flag (Absolute Path to the CA certificate file)
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
# --cert: Mandatory Flag (Absolute Path to the Server certificate file | public key)
--cert=/etc/kubernetes/pki/etcd/server.crt \
# --key: Mandatory Flag (Absolute Path to the Key file | privte key)
--key=/etc/kubernetes/pki/etcd/server.key \
snapshot save /opt/snapshot-pre-boot.db

ls /opt  # view the backup file

# restore etcd from backup
ETCDCTL_API=3 etcdctl --data-dir /var/lib/etcd-from-backup snapshot restore /opt/snapshot-pre-boot.db
vi /etc/kubernetes/manifests/etcd.yaml  # after restoring, edit the yaml for etcd pod and update the volumes and volumeMounts
# volumes:
# - hostPath:
#     path: /var/lib/etcd-from-backup
#     type: DirectoryOrCreate
#   name: etcd-data

# volumeMounts:
# - mountPath: /var/lib/etcd-from-backup
#   name: etcd-data

# backup etcd from another machine/cluster
kubectl get nodes
ssh cluster1-controlplane
cat /etc/kubernetes/manifests/etcd.yaml
kubectl describe pods -n kube-system etcd-cluster1-controlplane | grep advertise-client-urls  # https://192.160.244.10:2370
kubectl describe pods -n kube-system etcd-cluster1-controlplane | grep pki  # get values for --cacert, --cert, and --key
ETCDCTL_API=3 etcdctl --endpoints=https://192.160.244.10:2370 \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--cert=/etc/kubernetes/pki/etcd/server.crt \
--key=/etc/kubernetes/pki/etcd/server.key \
snapshot save /opt/cluster1.db

# copy the backup to another machine
scp cluster1-controlplane:/opt/cluster1.db /opt

ssh node01
service kubelet status

# restore and backup ETCD from another machine/cluster with External ETCD server
kubectl config get-contexts
kubectl config use-context cluster2
kubectl get po -n kube-system | grep etcd
ls /etc/kubernetes/manifests/ | grep -i etcd
ps ef | grep -i etcd
kubectl -n kube-system decribe pod kube-api-server-cluster2-controlplane
# external etcd (ETCD server not running on this cluster)
    #   --etcd-cafile=/etc/kubernetes/pki/etcd/ca.pem
    #   --etcd-certfile=/etc/kubernetes/pki/etcd/etcd.pem
    #   --etcd-keyfile=/etc/kubernetes/pki/etcd/etcd-key.pem
    #   --etcd-servers=https://192.22.46.12:2379
ssh cluster2-controlplane ps -ef | grep etcd  # find address of the etcd server
ssh etcd-server
ps -ef | grep --color=auto etcd
# Check the members of the ETCD cluster:
ETCDCTL_API=3 etcdctl \
--endpoint=https://127.0.0.1:2379 \
--cacert=/etc/etcd/pki/ca.pem \
--cert=/etc/etcd/pki/etcd.pem \
--key=/etc/etcd/pki/etcd-key.pem \
member list
# 59ee55985632d394, started, etcd-server, https://192.160.244.3:2380, https://192.160.244.3:2379, false  => only one node in ETCD server
# backup is created in another machine. copy it to the ETCD server
scp /opt/cluster2.db etcd-server:/root
ETCDCTL_API=3 etcdctl snapshot restore /root/cluster2.db --data-dir /var/lib/etcd-data-new
ls -la /var/lib 
# it should be owned by etcd user/group not root
chown -R etcd:etcd /var/lib/etcd-data-new/
# edit the etcd service so it uses new data
vi /etc/systemd/system/etcd.service
    # --data-dir=/var/lib/etcd-data-new
systemctl daemon-reload
systemctl restart etcd
systemctl status etcd
# go back to controlplane and restart kube-controller-manager, kube-scheduler, kubelet service to make sure they use new etcd
kubectl delete pods kube-controller-manager-* kube-scheduler-* -n kube-system
systemctl restart kubelet
# pods should be working properly
kubectl get deploy -n web-apps

# *** how can restoring an older version of etcd cluster restore deployments and daemonsets automatically?
# Restoring an older version of an etcd cluster can automatically restore Kubernetes resources like Deployments and DaemonSets because etcd is the primary data store for Kubernetes. Here's how it works:
# 1. **etcd as the Data Store**: In a Kubernetes cluster, etcd is used to store the entire state of the cluster. This includes all the configuration data, the state of all the resources (like Pods, Deployments, Services, etc.), and the cluster metadata.
# 2. **Snapshot and Restore**: When you take a snapshot of your etcd cluster, you are capturing the entire state of the Kubernetes cluster at that point in time. This snapshot includes all the information about Deployments, DaemonSets, and other resources.
# 3. **Restoring etcd**: When you restore an etcd snapshot, you are effectively reverting the cluster's state to what it was at the time the snapshot was taken. This means that all the resources that existed at that time, including Deployments and DaemonSets, 
# are restored to their previous state.
# 4. **Automatic Reconciliation**: Kubernetes has a reconciliation loop that continuously works to ensure that the actual state of the cluster matches the desired state as defined in etcd. When you restore etcd, the desired state is updated to reflect 
# the snapshot, and Kubernetes will automatically work to bring the actual state of the cluster in line with this restored desired state. This means that any Deployments or DaemonSets that were present in the snapshot will be recreated and managed 
# according to their specifications.
# In summary, restoring an etcd snapshot effectively rolls back the entire cluster to a previous state, including all the resources and configurations that were present at that time. Kubernetes then automatically reconciles the cluster to match this 
# restored state, which includes recreating Deployments and DaemonSets as needed.

# Certificates

# What is the Common Name (CN) configured on the Kube API Server Certificate?
cat /etc/kubernetes/pki/apiserver.crt
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
                  # Certificate:
                  #     Data:
                  #         Version: 3 (0x2)
                  #         Serial Number: 3378315762146779274 (0x2ee230495ddca08a)
                  #         Signature Algorithm: sha256WithRSAEncryption
                  #         Issuer: CN = kubernetes  #####################
                  #         Validity 
                  #             Not Before: Nov 16 14:16:29 2024 GMT
                  #             Not After : Nov 16 14:21:29 2025 GMT  #####################
                  #         Subject: CN = kube-apiserver
                  #         Subject Public Key Info:
                  #             Public Key Algorithm: rsaEncryption
                  #                 Public-Key: (2048 bit)
                  #                 Modulus:
                  #                     00:...
                  #                     bc:17
                  #                 Exponent: 65537 (0x10001)
                  #         X509v3 extensions:
                  #             X509v3 Key Usage: critical
                  #                 Digital Signature, Key Encipherment
                  #             X509v3 Extended Key Usage:
                  #                 TLS Web Server Authentication
                  #             X509v3 Basic Constraints: critical
                  #                 CA:FALSE
                  #             X509v3 Authority Key Identifier: A1:...
                  #             X509v3 Subject Alternative Name:
                  #                 DNS:controlplane, DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local, IP Address:10.96.0.1, IP Address:192.15.155.9
                  #     Signature Algorithm: sha256WithRSAEncryption
                  #     Signature Value: 65:...
                  
# How long, from the issued date, is the Kube-API Server Certificate valid for?
#  Validity
#       Not Before: Nov 16 14:16:29 2024 GMT
#       Not After : Nov 16 14:21:29 2025 GMT

# How long, from the issued date, is the Root CA Certificate valid for?
# --client-ca-file=/etc/kubernetes/pki/ca.cert
ls /etc/kubernetes/pki/
openssl x509 -in /etc/kubernetes/pki/ca.crt -text --noout
#    Validity
#         Not Before: Nov 16 14:16:29 2024 GMT
#         Not After : Nov 14 14:21:29 2034 GMT

# What is the Common Name (CN) configured on the ETCD Server certificate?
cat /etc/kubernetes/pki/etcd/server.crt
openssl x509 -in /etc/kubernetes/pki/etcd/server.crt -text -noout
# cn = etcd-ca

# Kubectl suddenly stops responding to your commands. Check it out! Someone recently modified the /etc/kubernetes/manifests/etcd.yaml file
cat  /etc/kubernetes/manifests/etcd.yaml
ls -l /etc/kubernetes/pki/etcd/server* | grep .crt
# -rw-r--r-- 1 root root 1208 Nov 16 14:21 /etc/kubernetes/pki/etcd/server.crt
# Update the "etcd.yaml" YAML file with the correct certificate path and wait for the ETCD pod to be recreated. wait for the kube-apiserver to get to a Ready state.

# The kube-apiserver stopped again! Check it out. Inspect the kube-apiserver logs and identify the root cause and fix the issue.
# Run "docker ps -a" command to identify the kube-apiserver container. Run "docker logs <container-id>" command to view the logs
docker ps -a | grep kube-apiserver
docker logs --tail=2 1fb242055cff8
# clientconn.go:1331] [core] grpc: addrConn.createTransport failed to connect to {127.0.0.1:2379 127.0.0.1 <nil> 0 <nil>}. Err: connection error: desc = "transport: authentication handshake failed: x509: certificate signed by unknown authority". Reconnecting...
# run.go:74] "command failed" err="context deadline exceeded"
docker ps -a | grep etcd
docker logs --tail 1f24332055cfvnv  # you can see connection errors here

# "127.0.0.1:2379" is address of ETCD server
# This indicates an issue with the "ETCD CA certificate" used by the kube-apiserver. Correct it to use the file /etc/kubernetes/pki/etcd/ca.crt
vi /etc/kubernetes/manifests/kube-apiserver.yaml
# - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt

# Create a CertificateSigningRequest object with the name babak with the contents of the babak.csr file
# CSR = Certificate Signing Request
cat babak.csr | base64 -w 0
        # apiVersion: certificates.k8s.io/v1
        # kind: CertificateSigningRequest
        # metadata:
        #  name: babak
        # spec:
        #  groups:
        #  - system:authenticated
        #  requests: LS0tLS1CRU...
        #  # Please note that an additional field called signerName should also be added when creating CSR.
        #  # For client authentication to the API server we will use the built-in signer "kubernetes.io/kube-apiserver-client"
        #  signerName: kubernetes.io/kube-apiserver-client
        #  usage:
        #  - client auth
k apply -f babak.csr.yaml
k get csr
k get csr babak
#   NAME     AGE   SIGNERNAME                            REQUESTOR          REQUESTEDDURATION   CONDITION
#   babak   44s   kubernetes.io/kube-apiserver-client   kubernetes-admin   <none>              Pending
k certificate approve babak
# certificatesigningrequest.certificates.k8s.io/babak approved
k get csr agent-smith -o yaml
k certificate deny agent-smith
# certificatesigningrequest.certificates.k8s.io/agent-smith denied
k delete csr agent-smith

# KUBECONFIG
k config --kubeconfig=/root/my-kube-config use-context research
k config --kubeconfig=/root/my-kube-config current-context
# change current kubeconfig file
cp my-custom-config ~/.kube/config

# The path to certificate is incorrect in the kubeconfig file. Correct the certificate name which is available at /etc/kubernetes/pki/users/
# Inspect the environment and identify the authorization modes configured on the cluster.
k describe pod kube-apiserver-controlplane -n kube-system | grep auth
#  --authorization-mode=Node,RBAC

# A user dev-user is created. User's details have been added to the kubeconfig file. Inspect the permissions granted to the user. Check if the user can list pods in the default namespace.
cat /root/.kube/config
kubectl get pods --as dev-user
#   Error from server (Forbidden): pods is forbidden: User "dev-user" cannot list resource "pods" in API group "" in the namespace "default"
# if you want to give access to user to see objects in different namespace, then he needs role and rolebinding that exist in that namespace

# What is the network interface configured for cluster connectivity on the controlplane node?
# kubectl get nodes -o wide to see the IP address assigned to the controlplane node
kubectl get nodes controlplane -o wide
# TO DO THIS YOU NEED TO SSH INSIDE THE NODE
# Next, find the network interface to which this IP is assigned by making use of the "ip link" command
ip a | grep 192.168.227.81
#   inet 192.168.227.81/32 scope global eth0
# Here you can see that the interface associated with this IP is "eth0" on the host.

# What is the MAC address of the interface on the controlplane node?
# use the network interface that was discoved before to find the mac address
ip link show eth0
#   3: eth0@if4065: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1410 qdisc noqueue state UP mode DEFAULT group default
#   link/ether 26:87:84:a7:3e:a8 brd ff:ff:ff:ff:ff:ff link-netnsid 0
# The MAC address is 26:87:84:a7:3e:a8

# We use "ContainerD" as our container runtime. What is the interface/bridge created by Containerd on the controlplane node?
# Run the command: "ip link" and look for a bridge interface created by containerd.
ip link
ip link show type bridge
# cni0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1360 qdisc noqueue state UP group default qlen 1000
#         link/ether e6:51:25:e1:b9:6a brd ff:ff:ff:ff:ff:ff
#         inet 172.17.0.1/24 brd 172.17.0.255 scope global cni0
#         valid_lft forever preferred_lft forever
#         inet6 fe80::e451:25ff:fee1:b96a/64 scope link
#         valid_lft forever preferred_lft forever

# What is the state of the interface cni0?
ip link show cni0
#     5: cni0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1360 qdisc noqueue state UP mode DEFAULT group default qlen 1000
#         link/ether e6:51:25:e1:b9:6a brd ff:ff:ff:ff:ff:ff
# UP

# If you were to ping google from the controlplane node, which route does it take?
# what is the ip address of the Default Gateway?
ip route show default
# default via 169.254.1.1 dev eth0

# What is the port the kube-scheduler is listening on in the controlplane node?
netstat -nplt | grep scheduler
#  tcp        0      0 127.0.0.1:10259   0.0.0.0:*   LISTEN   3665/kube-scheduler
# kube-scheduler process binds to the port 10259 on the controlplane node

# ETCD is listening on several ports. Which of these have more client connections established?
netstat -nplt | grep etcd
# tcp        0      0 127.0.0.1:2379          0.0.0.0:*               LISTEN      3182/etcd
# tcp        0      0 127.0.0.1:2381          0.0.0.0:*               LISTEN      3182/etcd
# tcp        0      0 192.168.231.169:2380    0.0.0.0:*               LISTEN      3182/etcd
# tcp        0      0 192.168.231.169:2379    0.0.0.0:*               LISTEN      3182/etcd
netstat -anp | grep etcd | grep 2380 | wc -l  # 1
netstat -anp | grep etcd | grep 2379 | wc -l  # 61
netstat -anp | grep etcd | grep 2381 | wc -l  # 1
# That's because 2379 is the port of ETCD to which all control plane components connect to. 2380 is only for etcd peer-to-peer connectivity. 
# When you have multiple controlplane nodes. In this case we don't.

# how to install weavnet plugin on kubernetes cluster
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

# Inspect the kubelet service and identify the container runtime endpoint value is set for Kubernetes.
ps -aux | grep kubelet | grep container-runtime-endpoint
#  root  4086  0.0  0.1 3005224 94652 ?  Ssl  14:15   0:16 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf \
# --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \
# --pod-infra-container-image=registry.k8s.io/pause:3.10

# CNI = Container Network Interface, a specification and a set of libraries for configuring network interfaces in Linux containers. CNI is used primarily in container orchestration platforms like Kubernetes to manage the networking aspects of containers

# What is the path configured with all binaries of CNI supported plugins?
# all plugins are stored at /opt/cni/bin
ls /opt/cni/bin
# what is the CNI plugin configured to be used on this kubernetes cluster?
ls /etc/cni/net.d/  # 10-flannel.conflist
# what binary executable file will be run by kubelet after a container and its associated namespace are created?
cat /etc/cni/net.d/10-flannel.conflist | grep type
 # flannel

# deploy weave-net networking solution to the cluster:
# download the weavenet yaml file
wget https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
# check kubeproxy
k describe pod kube-proxy-xxx -n kube-system | grep --config
#  --config=/var/lib/kube-proxy/config.conf
k describe cm kube-proxy -n kube-system | grep clusterCIDR
# clusterCIDR: 10.244.0.0/16
vi weave-daemonset-k8s.yaml
# go to containers section, find weave container and set the environment variable accodring to clusterCIDR:
# env:
#   - name: IPALLOC_RANGE
#     value: 10.244.0.0/16
k apply -f weave-daemonset-k8s.yaml
# should be one weave daemonset on each node
k get po -n kube-system | grep weave
# on which nodes are the weave peers present?
k get po -n kube-system -o wide | grep weave
# identify name of the bridge network/interface created by weave on each node
ip add | grep weave
# what is the pod ip adress range configured by weave?
k logs weave-net-xxx -n kube-system | grep ipalloc-range
# ipalloc-range: 10.244.0.0/16

# what is the default gateway configured on pods scheduled on "node01" ?
# try scheduling a pod on node01 and check the "ip route" output
kubectl run busybox --image=busybox --dry-run=client -o yaml > busybox.yaml
vi busybox.yaml
# spec:
#   nodeName: node01
kubectl apply -f busybox.yaml
kubectl exec busybox -- ip route
#  default via 10.244.192.0 dev eth0


# Install the kubeadm and kubelet packages on the controlplane and node01 nodes. Use the exact version of 1.31.0-1.1 for both.
# These steps have to be performed on both nodes:
# install container runtime (containerd) *********
# Enanble IPV4 packet forwarding
# sysctl params required by setup, params persists across reboots:
# cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
# net.ipv4.ip_forward =1
# EOF

# apply sysctl params without reboot
sudo sysctl --system
# Verify that net.ipv4.ip_forward is set to 1 with:
sysctl net.ipv4.ip_forward
# Update the apt package index and install packages needed to use the Kubernetes apt repository:
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
# Download the public signing key for the Kubernetes package repositories. The same signing key is used for all repositories so you can disregard the version in the URL:
# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
sudo mkdir -o -m 755 /etc/apt/keyring
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# Add the appropriate Kubernetes apt repository. Please note that this repository have packages only for Kubernetes 1.31; for other Kubernetes minor versions,
# you need to change the Kubernetes minor version in the URL to match your desired minor version (you should also check that you are reading the documentation
# for the version of Kubernetes that you plan to install).
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
# Update the apt package index, install kubelet, kubeadm and kubectl, and pin their version:
sudo apt-get update
sudo apt-cache madison kubeadm
sudo apt-get install -y kubelet=1.31.0-1.1 kubeadm=1.31.0-1.1 kubectl=1.31.0-1.1
sudo apt-mark hold kubelet kubeadm kubectl
# Enable the kubelet service before running kubeadm:
sudo systemctl enable --now kubelet
# What is the version of kubelet installed?
kubelet --version  # Kubernetes v1.31.0

# Initialize ControlPlane Node (Master Node). Use the following options:
# You can use the below kubeadm init command to spin up the cluster:
   # apiserver-cert-extra-sans => Set it to controlplane
   # apiserver-advertise-address => Use the IP address allocated to eth0 on the controlplane node
   # pod-network-cidr => Set to 10.244.0.0/16
   # Once done, set up the default kubeconfig file and wait for node to be part of the cluster.
IP_ADDR=$(ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
kubeadm init --apiserver-cert-extra-sans=controlplane --apiserver-advertise-address=$IP_ADDR --pod-network-cidr=10.244.0.0/16
                # [init] Using Kubernetes version: v1.31.0
                # [preflight] Running pre-flight checks
                # [preflight] Pulling images required for setting up a Kubernetes cluster
                # [preflight] This might take a minute or two, depending on the speed of your internet connection
                # [preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
                # W0529 15:35:11.112522   11469 checks.go:844] detected that the sandbox image "registry.k8s.io/pause:3.6" of the container runtime is inconsistent with that used by kubeadm.It is recommended to use "registry.k8s.io/pause:3.9" as the CRI sandbox image.
                # [certs] Using certificateDir folder "/etc/kubernetes/pki"
                # [certs] Generating "ca" certificate and key
                # [certs] Generating "apiserver" certificate and key
                # [certs] apiserver serving cert is signed for DNS names [controlplane kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 192.133.43.3]
                # [certs] Generating "apiserver-kubelet-client" certificate and key
                # [certs] Generating "front-proxy-ca" certificate and key
                # [certs] Generating "front-proxy-client" certificate and key
                # [certs] Generating "etcd/ca" certificate and key
                # [certs] Generating "etcd/server" certificate and key
                # [certs] etcd/server serving cert is signed for DNS names [controlplane localhost] and IPs [192.133.43.3 127.0.0.1 ::1]
                # [certs] Generating "etcd/peer" certificate and key
                # [certs] etcd/peer serving cert is signed for DNS names [controlplane localhost] and IPs [192.133.43.3 127.0.0.1 ::1]
                # [certs] Generating "etcd/healthcheck-client" certificate and key
                # [certs] Generating "apiserver-etcd-client" certificate and key
                # [certs] Generating "sa" key and public key
                # [kubeconfig] Using kubeconfig folder "/etc/kubernetes"
                # [kubeconfig] Writing "admin.conf" kubeconfig file
                # [kubeconfig] Writing "super-admin.conf" kubeconfig file
                # [kubeconfig] Writing "kubelet.conf" kubeconfig file
                # [kubeconfig] Writing "controller-manager.conf" kubeconfig file
                # [kubeconfig] Writing "scheduler.conf" kubeconfig file
                # [etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
                # [control-plane] Using manifest folder "/etc/kubernetes/manifests"
                # [control-plane] Creating static Pod manifest for "kube-apiserver"
                # [control-plane] Creating static Pod manifest for "kube-controller-manager"
                # [control-plane] Creating static Pod manifest for "kube-scheduler"
                # [kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
                # [kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
                # [kubelet-start] Starting the kubelet
                # [wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests"
                # [kubelet-check] Waiting for a healthy kubelet. This can take up to 4m0s
                # [kubelet-check] The kubelet is healthy after 553.930452ms
                # [api-check] Waiting for a healthy API server. This can take up to 4m0s
                # [api-check] The API server is healthy after 12.503398796s
                # [upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
                # [kubelet] Creating a ConfigMap "kubelet-config" in namespace kube-system with the configuration for the kubelets in the cluster
                # [upload-certs] Skipping phase. Please see --upload-certs
                # [mark-control-plane] Marking the node controlplane as control-plane by adding the labels: [node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
                # [mark-control-plane] Marking the node controlplane as control-plane by adding the taints [node-role.kubernetes.io/control-plane:NoSchedule]
                # [bootstrap-token] Using token: 90l0iw.8sa7trjypfybs5l1
                # [bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
                # [bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to get nodes
                # [bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
                # [bootstrap-token] Configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
                # [bootstrap-token] Configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
                # [bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
                # [kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
                # [addons] Applied essential addon: CoreDNS
                # [addons] Applied essential addon: kube-proxy

                # Your Kubernetes control-plane has initialized successfully!
                # To start using your cluster, you need to run the following as a regular user:
                #         mkdir -p $HOME/.kube
                #         sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
                # sudo chown $(id -u):$(id -g) $HOME/.kube/config
                # Alternatively, if you are the root user, you can run:
                #         export KUBECONFIG=/etc/kubernetes/admin.conf
                # You should now deploy a pod network to the cluster.
                # Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
                # https://kubernetes.io/docs/concepts/cluster-administration/addons/
                
                # Then you can join any number of worker nodes by running the following on each as root:
                #         kubeadm join 192.133.43.3:6443 --token 90l0iw.8sa7trjypfybs5l1 \
                #                 --discovery-token-ca-cert-hash sha256:a3793ea96e136d50cb06a5f380c134d00f3f9596a28ffb1dce110995eb29ea4d

# Once the command has been run successfully, set up the kubeconfig:
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):(id -g) $HOME/.kube/config
# Generate a kubeadm join token Or copy the one that was generated by kubeadm init command
kubeadm join 192.133.43.3:6443 --token 90l0iw.8sa7trjypfybs5l1 --discovery-token-ca-cert-hash sha256:a3793ea96e136d50cb06a5f380c134d00f3f9596a28ffb1dce110995eb29ea4d
        #   [preflight] Running pre-flight checks
        #   [preflight] Reading configuration from the cluster...
        #   [preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
        #   [kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
        #   [kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
        #   [kubelet-start] Starting the kubelet
        #   [kubelet-check] Waiting for a healthy kubelet at http://127.0.0.1:10248/healthz. This can take up to 4m0s
        #   [kubelet-check] The kubelet is healthy after 1.00098712s
        #   [kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap
        #   This node has joined the cluster:
        #   * Certificate signing request was sent to apiserver and a response was received.
        #   * The Kubelet was informed of the new secure connection details.
        #   Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

k -n kube-system get cm kubeadm-config -o yaml
k get nodes
# To install a network plugin, we will go with Flannel as the default choice. For inter-host communication, we will utilize the eth0 interface.
k apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yaml
k get po -n kube-flannel


# Fixing Cluster Issues

# The cluster is broken. We tried deploying an application but it's not working. Troubleshoot and fix the issue.
k get po -n kube-system
# NAME                                   READY   STATUS             RESTARTS      AGE
# coredns-77d6fd4654-dgsgn               1/1     Running            0             17m
# coredns-77d6fd4654-tkz6s               1/1     Running            0             17m
# etcd-controlplane                      1/1     Running            0             17m
# kube-apiserver-controlplane            1/1     Running            0             17m
# kube-controller-manager-controlplane   1/1     Running            0             17m
# kube-proxy-vxjlk                       1/1     Running            0             17m
# kube-scheduler-controlplane            0/1     CrashLoopBackOff   8 (28s ago)   16m   ####

k get po kube-scheduler-controlplane -n kube-system -o wide
#     NAME                          READY   STATUS             RESTARTS        AGE   IP               NODE           NOMINATED NODE   READINESS GATES
#     kube-scheduler-controlplane   0/1     CrashLoopBackOff   8 (2m47s ago)   18m   192.168.122.99   controlplane   <none>           <none>

# kube-scheduler is an static pod
cat /etc/kubernetes/manifests/kube-scheduler.yaml
vi /etc/kubernetes/manifests/kube-scheduler.yaml
#       spec:
#         containers:
#         - command:
#           - --kubeconfig=/etc/kubernetes/scheduler.conf   # this was wrong and needed to be fixed

k get po -n kube-system --watch

# Even though the deployment was scaled to 2, the number of PODs does not seem to increase. Investigate and fix the issue.
# Inspect the component responsible for managing deployments and replicasets.
k describe deploy app # everything seems fine
k get po -n kube-system
#  NAME                                   READY   STATUS             RESTARTS      AGE
#  coredns-77d6fd4654-kcqp4               1/1     Running            0             18m
#  coredns-77d6fd4654-rvrk4               1/1     Running            0             18m
#  etcd-controlplane                      1/1     Running            0             18m
#  kube-apiserver-controlplane            1/1     Running            0             18m
#  kube-controller-manager-controlplane   0/1     CrashLoopBackOff   7 (88s ago)   12m   ###
#  kube-proxy-d4z2v                       1/1     Running            0             18m
#  kube-scheduler-controlplane            1/1     Running            1 (13m ago)   12m

k logs kube-controller-manager-controlplane -n kube-system
# Generated self-signed cert in-memory
# "command failed" err="stat /etc/kubernetes/controller-manager-xxx.conf: no such file or directory"
cat /etc/kubernetes/manifests/kube-controller-manager.yaml
vi /etc/kubernetes/manifests/kube-controller-manager.yaml
        # spec:
        # containers:
        # - command:
        #     - --kubeconfig=/etc/kubernetes/controller-manager-xxx.conf   #### correct it to "controller-manager.conf"

# Something is wrong with scaling again. We just tried scaling the deployment to 3 replicas. But it's not happening.
k get deploy
k describe deploy 
# Replicas:  3 desired | 2 updated | 2 total | 2 available | 0 unavailable
k get po -n kube-system
# NAME                                   READY   STATUS             RESTARTS      AGE
# coredns-77d6fd4654-kcqp4               1/1     Running            0             38m
# coredns-77d6fd4654-rvrk4               1/1     Running            0             38m
# etcd-controlplane                      1/1     Running            0             38m
# kube-apiserver-controlplane            1/1     Running            0             38m
# kube-controller-manager-controlplane   0/1     CrashLoopBackOff   5 (16s ago)   3m27s         ####
# kube-proxy-d4z2v                       1/1     Running            0             38m
# kube-scheduler-controlplane            1/1     Running            1 (33m ago)   32m

k logs kube-controller-manager-controlplane -n kube-system
# Generated self-signed cert in-memory
# "command failed" err="unable to load client CA provider: open /etc/kubernetes/pki/ca.crt: no such file or directory"

ls /etc/kubernetes/pki/ca.crt # this file should be mounted within controller manager as volume
cat /etc/kubernetes/manifests/kube-controller-manager.yaml
cat /etc/kubernetes/manifests/kube-controller-manager.yaml | grep /etc/kubernetes/pki/ca.crt
#     - --client-ca-file=/etc/kubernetes/pki/ca.crt
#     - --cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt
#     - --root-ca-file=/etc/kubernetes/pki/ca.crt

vi /etc/kubernetes/manifests/kube-controller-manager.yaml
# Check the volume mount path in kube-controller-manager manifest file at /etc/kubernetes/manifests.
# It appears the path /etc/kubernetes/pki is not mounted from the controlplane to the kube-controller-manager pod. If we inspect the pod manifest file,
# we can see that the incorrect hostPath is used for the volume:

# volumeMounts:
# - mountPath: /etc/kubernetes/pki   # this is where we save it on the pod
#   name: k8s-certs

## WRONG:
# volumes:
# - hostPath:
#    path: /etc/kubernetes/WRONG-PKI-DIRECTORY  # change this
#    type: DirectoryOrCreate
#   name: k8s-certs

## CORRECT:
# volumes:
# - hostPath:
#    path: /etc/kubernetes/pki  # this is where we access it from the node
#    type: DirectoryOrCreate
#  name: k8s-certs

# Once the path is corrected, the pod will be recreated and our deployment should eventually scale up to 3 replicas.

# The cluster is broken again. Investigate and fix the issue.
k get nodes
# NAME           STATUS     ROLES           AGE   VERSION
# controlplane   Ready      control-plane   22m   v1.31.0
# node01         NotReady   <none>          22m   v1.31.0
k describe node01
# Type                 Status    LastHeartbeatTime                 LastTransitionTime                Reason              Message
# NetworkUnavailable   False     Sat, 30 Nov 2024 15:59:35 +0000   Sat, 30 Nov 2024 15:59:35 +0000   FlannelIsUp         Flannel is running on this node
# MemoryPressure       Unknown   Sat, 30 Nov 2024 15:59:59 +0000   Sat, 30 Nov 2024 16:03:54 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
# DiskPressure         Unknown   Sat, 30 Nov 2024 15:59:59 +0000   Sat, 30 Nov 2024 16:03:54 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
# PIDPressure          Unknown   Sat, 30 Nov 2024 15:59:59 +0000   Sat, 30 Nov 2024 16:03:54 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
# Ready                Unknown   Sat, 30 Nov 2024 15:59:59 +0000   Sat, 30 Nov 2024 16:03:54 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
ssh node01
service kubelet status
#     ○ kubelet.service - kubelet: The Kubernetes Node Agent
#          Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
#          Drop-In: /usr/lib/systemd/system/kubelet.service.d
#                  └─10-kubeadm.conf
#          Active: inactive (dead) since Sat 2024-11-30 16:03:15 UTC; 22min ago
#            Docs: https://kubernetes.io/docs/
#         Process: 2583 ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS (code=exited, status=0/SUCCESS)
#        Main PID: 2583 (code=exited, status=0/SUCCESS)

# "Running under a user namespace - tmpfs noswap is not supported"
# "Observed pod startup duration" pod="kube-system/kube-proxy-wzpwz" po>
# "Fast updating node status as it just became ready"
# "Shutting down controller" name="client-ca-bundle::/etc/kubernetes/
service kubelet start
service kubelet status
#   ● kubelet.service - kubelet: The Kubernetes Node Agent
#        Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
#       Drop-In: /usr/lib/systemd/system/kubelet.service.d
#                └─10-kubeadm.conf
#        Active: active (running) since Sat 2024-11-30 16:26:49 UTC; 7s ago

# The cluster is broken again. Investigate and fix the issue.
k get nodes
#  NAME           STATUS     ROLES           AGE   VERSION
#  controlplane   Ready      control-plane   30m   v1.31.0
#  node01         NotReady   <none>          30m   v1.31.0
k describe node node01
# Warning  InvalidDiskCapacity      3m                 kubelet          invalid capacity 0 on image filesystem
# Normal   NodeAllocatableEnforced  3m                 kubelet          Updated Node Allocatable limit across pods
# Normal   NodeHasSufficientMemory  3m (x2 over 3m)    kubelet          Node node01 status is now: NodeHasSufficientMemory
# Normal   NodeHasNoDiskPressure    3m (x2 over 3m)    kubelet          Node node01 status is now: NodeHasNoDiskPressure
# Normal   NodeHasSufficientPID     3m (x2 over 3m)    kubelet          Node node01 status is now: NodeHasSufficientPID
# Normal   NodeNotReady             34s (x2 over 25m)  node-controller  Node node01 status is now: NodeNotReady
ssh node01
service kubelet status
#       ● kubelet.service - kubelet: The Kubernetes Node Agent
#            Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
#           Drop-In: /usr/lib/systemd/system/kubelet.service.d
#                    └─10-kubeadm.conf
#            Active: activating (auto-restart) (Result: exit-code) since Sat 2024-11-30 16:30:50 UTC; 3s ago
#              Docs: https://kubernetes.io/docs/
#           Process: 16744 ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_>
#          Main PID: 16744 (code=exited, status=1/FAILURE)
journalctl -u kubelet
# Flag --pod-infra-container-image has been deprecated, will be removed in a future release. Image garbage collector will get sandbox image information from CRI.
# "--pod-infra-container-image will not be pruned by the image garbage collector in kubelet and should also be set in the remote>
# "command failed" err="failed to construct kubelet dependencies: unable to load client CA file /etc/kubernetes/pki/WRONG-CA-FILE.cr>
# Flag --container-runtime-endpoint has been deprecated, This parameter should be set via the config file specified by the Kubelet's --config flag. See https://kubernetes.io>
# Flag --pod-infra-container-image has been deprecated, will be removed in a future release. Image garbage collector will get sandbox image information from CRI.
# "--pod-infra-container-image will not be pruned by the image garbage collector in kubelet and should also be set in the remote>
# "command failed" err="failed to construct kubelet dependencies: unable to load client CA file /etc/kubernetes/pki/WRONG-CA-FILE.cr

# failed to construct kubelet dependencies: unable to load client CA file /etc/kubernetes/pki/WRONG-CA-FILE.cr
# there is the kubeconfig file that kubelet uses to connect to master node
cat /var/lib/kubelet/config.yaml
# apiVersion: kubelet.config.k8s.io/v1beta1
# kind: KubeletConfiguration
# authentication:
#   anonymous:
#     enabled: false
#   webhook:
#     cacheTTL: 0s
#     enabled: true
#   x509:
#     clientCAFile: /etc/kubernetes/pki/WRONG-CA-FILE.crt   #### this is obviously wrong, change to "ca.crt" => /etc/kubernetes/pki/ca.crt
service kubelet restart

# the cluster is broken again, investigate and fix the issue
k get nodes
k describe nodes node01
# Normal   NodeHasSufficientMemory  2m47s (x2 over 2m48s)  kubelet          Node node01 status is now: NodeHasSufficientMemory
# Normal   NodeHasNoDiskPressure    2m47s (x2 over 2m48s)  kubelet          Node node01 status is now: NodeHasNoDiskPressure
# Normal   NodeHasSufficientPID     2m47s (x2 over 2m48s)  kubelet          Node node01 status is now: NodeHasSufficientPID
# Normal   NodeNotReady             103s (x3 over 40m)     node-controller  Node node01 status is now: NodeNotReady
ssh node01
service kubelet status
      # ● kubelet.service - kubelet: The Kubernetes Node Agent
      #      Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
      #     Drop-In: /usr/lib/systemd/system/kubelet.service.d
      #              └─10-kubeadm.conf
      #      Active: active (running) since Sat 2024-11-30 16:41:39 UTC; 5min ago
      #        Docs: https://kubernetes.io/docs/
      #    Main PID: 22489 (kubelet)
      #       Tasks: 23 (limit: 77143)
      #      Memory: 29.6M
      #      CGroup: /system.slice/kubelet.service
      #              └─22489 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --pod-infra-container-image=registry.k8s.io/pause:3.10
journalctl -u kubelet
      # kubelet_node_status.go:95] "Unable to register node with API server" err="Post \"https://controlplane:6553/api/v1/nodes\": dial tcp 192.168.227.122:6553: connect: connection refused" node="node01"
      # reflector.go:561] k8s.io/client-go/informers/factory.go:160: failed to list *v1.Node: Get "https://controlplane:6553/api/v1/nodes?fieldSelector=metadata.name%3Dnode01&limit=500&resourceVersion=0": dial tcp 192.168.227.122:6553: connect: connection refused
      # reflector.go:158] "Unhandled Error" err="k8s.io/client-go/informers/factory.go:160: Failed to watch *v1.Node: failed to list *v1.Node: Get \"https://controlplane:6553/api/v1/nodes?fieldSelector=metadata.name%3Dnode01&limit=500&resourceVersion=0\": dial tcp 192.168.227.122:6553: connect: connection refused" logger="UnhandledError"
      # event.go:368] "Unable to write event (may retry after sleeping)" err="Post \"https://controlplane:6553/api/v1/namespaces/default/events\": dial tcp 192.168.227.122:6553: connect: connection refused" event="&Event{ObjectMeta:{node01.180ccc959a5f28e1  default    0 0001-01-01 00:00:00 +0000 UTC <nil> <nil> map[] map[] [] [] []},InvolvedObject:O>
      # eviction_manager.go:285] "Eviction manager: failed to get summary stats" err="failed to get node info: node \"node01\" not found"
      # controller.go:145] "Failed to ensure lease exists, will retry" err="Get \"https://controlplane:6553/apis/coordination.k8s.io/v1/namespaces/kube-node-lease/leases/node01?timeout=10s\": dial tcp 192.168.227.122:6553: connect: connection refused" interval="7s"
      # kubelet_node_status.go:72] "Attempting to register node" node="node01"
      # kubelet_node_status.go:95] "Unable to register node with API server" err="Post \"https://controlplane:6553/api/v1/nodes\": dial tcp 192.168.227.122:6553: connect: connection refused" node="node01"   
# port number should be 6443 not 6553, "Unable to register node with API server" err="Post \"https://controlplane:6553/"
cat /etc/kubernetes/kubelet.conf  # this is the kubeconfig file that kubelet uses to connect to kube-apiserver
# apiVersion: v1
# clusters:
# - cluster:
#     certificate-authority-data: **** # CA 
#     server: https://controlplane:6553  #### here is the issue, change it to "6443"
service kubelet restart
service kubelet status  # should be running with no errors now


# Network Troubleshooting
# Network Plugin in Kubernetes
# There are several plugins available and these are some.
# 1. Weave Net:
# To install,
k apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
# You can find details about the network plugins in the following documentation :
# https://kubernetes.io/docs/concepts/cluster-administration/addons/#networking-and-network-policy

# 2. Flannel :
#  To install,
k apply -f https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml
# Note: As of now flannel does not support kubernetes network policies.

# 3. Calico :
# To install
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml -O
# Apply the manifest using the following command.
k apply -f calico.yaml
# Calico is said to have most advanced cni network plugin.

# IPAM = IP Address Management, deals with the planning, tracking, and managing of IP address space within a network.
# IPAM is responsible for assigning IP addresses to pods in a Kubernetes cluster
# IP Address Allocation: Calico's IPAM is responsible for allocating IP addresses to pods when they are created. It ensures that each pod receives a unique IP address from a predefined IP pool.
# IP Pools: Calico allows you to define IP pools, which are ranges of IP addresses that can be used for pod networking. You can configure multiple IP pools and specify which pools should be used for different namespaces or workloads.
# IPAM Modes: Calico supports different IPAM modes, such as: Calico IPAM: The default mode, where Calico manages IP address allocation and ensures efficient use of IP address space , HostLocal IPAM: An alternative mode where IP addresses are allocated from a local range on each node, rather than a global pool.

# **Troubleshooting Test 1:** A simple 2 tier application is deployed in the triton namespace. It must display a green web page on success. Click on the app tab
# at the top of your terminal to view your application. It is currently failed. Troubleshoot and fix the issue.
k get svc -n triton
      # NAME          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
      # mysql         ClusterIP   10.100.190.141   <none>        3306/TCP         2m33s
      # web-service   NodePort    10.111.38.4      <none>        8080:30081/TCP   2m33s

k get po -n kube-system
    # NAME                                   READY   STATUS    RESTARTS   AGE
    # coredns-6f6b679f8f-mtxzv               1/1     Running   0          33m
    # coredns-6f6b679f8f-qh272               1/1     Running   0          33m
    # etcd-controlplane                      1/1     Running   0          33m
    # kube-apiserver-controlplane            1/1     Running   0          33m
    # kube-controller-manager-controlplane   1/1     Running   0          33m
    # kube-proxy-smg6m                       1/1     Running   0          33m
    # kube-scheduler-controlplane            1/1     Running   0          33m

k logs -n kube-system kube-proxy-smg6m
      # server_linux.go:66] "Using iptables proxy"
      # server.go:677] "Successfully retrieved node IP(s)" IPs=["192.168.121.133"]
      # conntrack.go:121] "Set sysctl" entry="net/netfilter/nf_conntrack_max" value=131072
      # conntrack.go:60] "Setting nf_conntrack_max" nfConntrackMax=131072
      # conntrack.go:121] "Set sysctl" entry="net/netfilter/nf_conntrack_tcp_timeout_established" value=86400
      # conntrack.go:121] "Set sysctl" entry="net/netfilter/nf_conntrack_tcp_timeout_close_wait" value=3600
      # server.go:234] "Kube-proxy configuration may be incomplete or incorrect" err="nodePortAddresses is unset; NodePort connections will be accepted on all local IPs. Consider using `--nodeport-addresses primary`"
      # "kube-proxy running in dual-stack mode" primary ipFamily="IPv4"
      # server_linux.go:169] "Using iptables Proxier"
      # proxier.go:255] "Setting route_localnet=1 to allow node-ports on localhost; to change this either disable iptables.localhostNodePorts (--iptables-localhost-nodeports) or set nodePortAddresses (--nodeport-addresses) to filter loopback addresses" ipFamily="IPv4"
      # server.go:483] "Version info" version="v1.31.0"
      # server.go:485] "Golang settings" GOGC="" GOMAXPROCS="" GOTRACEBACK=""
      # config.go:326] "Starting node config controller"
      # shared_informer.go:313] Waiting for caches to sync for node config
      # config.go:197] "Starting service config controller"
      # shared_informer.go:313] Waiting for caches to sync for service config
      # config.go:104] "Starting endpoint slice config controller"
      # shared_informer.go:313] Waiting for caches to sync for endpoint slice config
      # shared_informer.go:320] Caches are synced for node config
      # shared_informer.go:320] Caches are synced for service config
      # shared_informer.go:320] Caches are synced for endpoint slice config

# there is no network plugin, we need to install one:
kubectl get po -A | grep weave
curl -L https://github.com/weaveworks/weave/releases/download/latest_release/weave-daemonset-k8s-1.11.yaml | kubectl apply -f -


# The same 2 tier application is having issues again. It must display a green web page on success. Click on the app tab at the top of your terminal to view your application. It is currently failed. Troubleshoot and fix the issue.
# Error: Environment Variables: DB_Host=mysql; DB_Database=Not Set; DB_User=root; DB_Password=paswrd; 2003: Can't connect to MySQL server on 'mysql:3306' (111 Connection refused)

k get po -A
    # NAMESPACE     NAME                                   READY   STATUS             RESTARTS        AGE
    # kube-system   coredns-6f6b679f8f-mtxzv               1/1     Running            0               58m
    # kube-system   coredns-6f6b679f8f-qh272               1/1     Running            0               58m
    # kube-system   etcd-controlplane                      1/1     Running            0               58m
    # kube-system   kube-apiserver-controlplane            1/1     Running            0               58m
    # kube-system   kube-controller-manager-controlplane   1/1     Running            0               58m
    # kube-system   kube-proxy-24rmj                       0/1     CrashLoopBackOff   9 (50s ago)     22m   #######
    # kube-system   kube-scheduler-controlplane            1/1     Running            0               58m
    # kube-system   weave-net-gjxcx                        2/2     Running            0               23m
    # triton        mysql                                  1/1     Running            4 (52s ago)     22m
    # triton        webapp-mysql-d89894b4b-hrt4v           1/1     Running            2 (9m22s ago)   22m

k logs -n kube-system kube-proxy-24rmj
    # run.go:74] "command failed" err="failed complete: open /var/lib/kube-proxy/configuration.conf: no such file or directory"

k get cm kube-proxy -n kube-system -o yaml
    # apiVersion: v1
    # data:
    #   config.conf: |-
    #     apiVersion: kubeproxy.config.k8s.io/v1alpha1
    #     bindAddress: 0.0.0.0
    #     bindAddressHardFail: false
    #     clientConnection:
    #       acceptContentTypes: ""
    #       burst: 0
    #       contentType: ""
    #       kubeconfig: /var/lib/kube-proxy/kubeconfig.conf   # this is correct address for kubeconfig
    #       qps: 0
    #     clusterCIDR: 10.244.0.0/16
    #     configSyncPeriod: 0s

k get ds kube-proxy -n kube-system -o yaml
      # apiVersion: apps/v1
      # kind: DaemonSet
      # metadata:
      #   labels:
      #     k8s-app: kube-proxy
      #   name: kube-proxy
      #   namespace: kube-system
      # spec:
      #   selector:
      #     matchLabels:
      #       k8s-app: kube-proxy
      #   template:
      #     metadata:
      #       labels:
      #         k8s-app: kube-proxy
      #     spec:
      #       containers:
      #       - command:
      #         - /usr/local/bin/kube-proxy
      #         - --config=/var/lib/kube-proxy/configuration.conf   # this is wrong and has to be changed to:  "/var/lib/kube-proxy/kubeconfig.conf"
      #         - --hostname-override=$(NODE_NAME)

kubectl edit daemonset kube-proxy -n kube-system

## JSON output
# Get the list of nodes in JSON format and store it in a file at /opt/outputs/nodes.json
k get nodes -o json > /opt/outputs/nodes.json

# Get the details of the node node01 in json format and store it in the file /opt/outputs/node01.json
k get node node01 -o json > /opt/outputs/node01.json

# Use JSON PATH query to fetch node names and store them in /opt/outputs/node_names.txt
k get nodes -o=jsonpath='{.items[*].metadata.name}' > /opt/outputs/node_names.txt

# Use JSON PATH query to retrieve the osImages of all the nodes and store it in a file /opt/outputs/nodes_os.txt
k get nodes -o=jsonpath='{.items[*].status.nodeinfo.osImage}' > /opt/outputs/node_os.txt



### Upgrade the current version of kubernetes from 1.30.0 to 1.31.0 exactly using the kubeadm utility. Make sure that the upgrade is carried out one node at a time starting with the controlplane node. 
# To minimize downtime, the deployment gold-nginx should be rescheduled on an alternate node before upgrading each node.
# upgrade controlplane node first and drain node node01 before upgrading it. pods for gold-nginx should run on the controlplane node subsequently

# on controlpnae node
vi /etc/apt/source.list.d/kubernetes.list
# Update the version in the URL to the next available minor release, i.e v1.31.
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring-gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /
kubectl drain controlplane --ignore-daemonsets
apt update
apt-cache madison kubeadm
apt-get install kubeadm=1.31.0-1.1
kubeadm upgrade plan v1.31.0
kubeadm upgrade apply v1.31.0
# upgrade kubelet
apt-get install kubelet=1.31.0-1.1
systemctl daemon-reload
systemctl restart kubelet
kubectl uncordon controlplane
# Before draining node01, if the controlplane gets taint during an upgrade, we have to remove it.
k describe node controlplane | grep -i taint
k taint node controlplane node-role.kubernetes.io/control-plane:NoSchedule-
k describe node controlplane | grep -i taint
# drain and upgrade node01
k drain node01 --ignore-daemonsets
# SSH to the node01 and perform the below steps as follows: -
vi /etc/apt/source.list.d/kubernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.kBs.10/core:/stable:/v1.31/deb/ /
apt update
apt-cache madison kubeadm
apt-get install kubeadm=1.31.0-1.1
kubeadm upgrade node
# upgrade kubelet
apt-get install kubelet=1.31.0-1.1
systemctl daemon-reload
systemctl restart kubelet
# exit back to controlplane node
k uncordon node01
k get pods -o wide | grep gold # make sure this is scheduled on a node

# isntall docker on nodes for kubertnets installation
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce
sudo systemctl status docker
sudo docker run hello-world
