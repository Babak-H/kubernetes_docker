############################################## CoreDNS, DNS, CNI, Weavenet

# Create a nginx pod called nginx-resolver using image nginx, expose it internally with a service called nginx-resolver-service. Test that you are able to look up 
# the service and pod names from within the cluster. Use the image: busybox: 1.28 for dns lookup (create another pod to test the service). Record results in /root/KA/nginx.svc and /root/CKA/nginx.pod
k run nginx-resolver --image=nginx
k expose po ngnix-resolver --name=nginx-resolver-service --port=80
k describe svc nginx-resolver-service # find its IP address
k get po nginx-resolver -o wide # get it's ip address

# only way to get logs from the pod to outside is run it in background, then exec to it and export results to some file
k run busybox --image busybox:1.28 -- sleep 4800
# since we are all on same namespace it can also be only : nginx-resolver-service
k exec busybox -- nslookup nginx-resolver-service.default.svc.cluster.local > /root/KA/nginx.svc
k exec busybox -- nslookup 10-244-192-2.default.pod.cluster.local > /root/CKA/nginx.pod

# From the hr pod nslookup the mysql service (in payroll namespace) and redirect the output to a file /root/CKA/nslookup.out
k exec hr -- nslookup mysql.payroll.svc.cluster.local > /root/CKA/nslook.out

# coreDNS version
k describe po coredns-xxx-xxx -n kube-system # coreDNS version is visible here

# coreDNS TTL?
# The TTL value used for CoreDNS lookup responses is configured within a 'ConfigMap' resource named 'coredns' located in the kube-system namespace. 
k get configmap codedns -n kube-system
  kubernetes cluster.local in-addr.arpa ip6.arpa {
      pods insecure
      fallthrough in-addr.arpa ip6.arpa
      ttl 30   ###
  }

# Determine whether there are any pods running on the cluster that are not using CoreDNS for DNS resolution ?
k get po -A -o=custom-columns="PodName:.metadata.name,DNSPOLICY:.spec.dnsPolicy"

# Determine the Pod CIDR range used by the cluster.
k get cm kube-proxy -n kube-system -o yaml | grep -i cidr  # 192.168.0.0/16

# Determine which CNI provider is currently being used, and how IPAM has been configured for the pod network.
# all CNI plugin configurartions and related things can be found at /etc/cni/net.d/
ssh controlplane
sudo -s
ls /opt/cni/bin  # lists all available CNI and installed one
cat /etc/cni/net.d/10-calico.conflist 
  "ipam": {
      "type": "calico-ipam"

# Which Networking (or CNI Plugin) is configured and where is its config file?
ls -la /etc/cni/net.d/
# /etc/cni/net.d/
# /etc/cni/net.d/10-weave.conflist

cat /etc/cni/net.d/10-weave.conflist
# {
#     "cniVersion": "0.3.0",
#     "name": "weave",

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

# how to find ipadress of a node?
kubectl get nodes -o wide

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


# a 2 tier application is having issues again. It must display a green web page on success. Click on the app tab at the top of your terminal to view your application. It is currently failed. Troubleshoot and fix the issue.
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

################################################################################### Networking Linux Commands
# Displays the network interfaces and their current statuses (up/down).
ip link

# Adds the IP address 192.168.1.10 with a subnet mask of 255.255.255.0 to the 'eth0' network interface
ip addr add 192.168.1.10/24 dev eth0

# Adds a route for the network 192.168.2.0/24, directing traffic through the gateway at IP address 192.168.1.1
ip route add 192.168.2.0/24 via 192.168.1.1

# Displays the current routing table in a more traditional format
route

# Adds a route for the network 192.168.1.0/24, directing traffic through the gateway at IP address 192.168.2.2
ip route add 192.168.1.0/24 via 192.168.2.2

# Displays the current setting of IP forwarding (whether routing between interfaces is enabled or not)
cat /proc/sys/net/ipv4/ip_forward

# Enables IP forwarding (routing between interfaces) by writing '1' to the sysctl configuration file.
echo 1 > /proc/sys/net/ipv4/ip_forward

# Displays the contents of the sysctl configuration file, which contains system-wide kernel parameters.
cat /etc/sysctl.conf

# Appends content to the '/etc/hosts' file, typically used for mapping hostnames to IP addresses.
cat >> /etc/hosts

# Displays the contents of the '/etc/resolv.conf' file, which specifies the DNS resolver configuration.
cat /etc/resolv.conf

# Displays the contents of the '/etc/nsswitch.conf' file, which configures the system's name service switch (how the system resolves hostnames and services).
cat /etc/nsswitch.conf

# Performs a DNS lookup for the domain 'www.google.com', returning the associated IP address.
nslookup www.google.com

# Another tool for performing a DNS lookup, with more detailed information compared to 'nslookup'.
dig www.google.com

# Extracts the 'coredns_1.4.0_linux_amd64.tgz' tarball file, decompressing and unpacking it.
tar -xzvf coredns_1.4.0_linux_amd64.tgz

# Runs the 'coredns' program with the DNS service listening on port 53.
./cordns -dns.port=53

# Starts 'tcpdump' to capture network packets, with the '-l' option making output line-buffered for easier reading.
tcpdump -l

# Adds a NAT (Network Address Translation) rule for the POSTROUTING chain, masquerading (hiding) source IP addresses for packets from the 192.168.5.0/24 network.
iptables -t nat -A POSTROUTING -s 192.168.5.0/24 -j MASQURADE

# Displays a list of all running processes with detailed information, such as CPU and memory usage.
ps -aux

# Creates a new network namespace named 'red', allowing for isolated network configurations.
ip netns add red

# Lists all the current network namespaces on the system.
ip netns

# Executes 'ip link' in the 'red' network namespace to display its network interfaces.
ip link exec red

# Displays network interfaces in the 'red' network namespace.
ip -n red link

# Displays the ARP (Address Resolution Protocol) cache, which maps IP addresses to MAC addresses.
arp

# Displays the ARP cache for the 'red' network namespace.
ip netns exec red arp

# Creates a pair of virtual Ethernet interfaces ('veth-red' and 'veth-blue') connected to each other.
ip link add veth-red type veth peer name veth-blue

# Moves the 'veth-red' interface into the 'red' network namespace.
ip link set veth-red netns red

# Adds the IP address 192.168.15.1 to the 'veth-red' interface in the 'red' network namespace.
ip -n red addr add 192.168.15.1 dev veth-red

# Brings the 'veth-red' interface up (activates it) in the 'red' network namespace.
ip -n red link set veth-red up

# Creates a new network bridge interface named 'v-net-0', which allows network traffic to be forwarded between interfaces.
ip link add v-net-0 type bridge

# Brings the 'v-net-0' bridge interface up.
ip link set dev v-net-0 up

# Creates a pair of virtual Ethernet interfaces ('veth-red' and 'veth-red-br') connected to each other.
ip link add veth-red type veth peer name veth-red-br

# Moves the 'veth-red' interface into the 'red' network namespace.
ip link set veth-red netns red

# Assigns the 'veth-red-br' interface as a port of the 'v-net-0' bridge, effectively connecting the bridge to this interface.
ip link set veth-red-br master v-net-0

# Adds the IP address 192.168.15.1 to the 'veth-red' interface in the 'red' network namespace.
ip -n red addr add 192.168.15.1 dev veth-red

# Brings the 'veth-red' interface up in the 'red' network namespace.
ip -n red link set veth-red up

# Adds a NAT(Network Address Translation) rule for destination IP address translation (DNAT) that redirects HTTP (port 80) traffic to IP 192.168.15.2 on port 80.
# this means whatever traffic that is coming to current machine on port 80 will be redirected to 192.168.15.2:80
iptables -t nat -A POSTROUTING --dport 80 --to-destination 192.168.15.2:80 -j DNAT

# Adds a DNAT rule for Docker containers, redirecting traffic on port 8080 on Host machine to a container IP address (172.17.0.3).
iptables -t nat -A DOCKER --dport 8080 --to-destination 172.17.0.3:8080 -j DNAT

# Lists all NAT rules, showing detailed information like packet and byte counts.
iptables -nvL -t nat

# Lists all rules in the specified table (if any, the 't' option would require a specific table name).
iptables -L -t

# Displays a list of all listening network connections/ports, with details on associated programs and processes.
netstat -plnt

# Performs a DNS lookup for the 'web-service' hostname, showing its resolved IP address.
host web-service

# Displays detailed information about the X.509 certificate located at '/var/lib/kubelet/worker-1.crt', including the certificate details in human-readable text format.
openssl x509 -n /var/lib/kubelet/worker-1.crt -text

# Retrieves the Kubernetes version, encodes it in base64 format, and removes(truncates) any newline characters.
kubectl version | base64 | tr -d '\n'

# /usr/include: This is a standard directory for header files that are used by programs compiled on the system.
# /linux: This directory contains various Linux-specific system headers, which define structures, constants, and functions for interacting with the Linux kernel.
# capability.h: This particular file defines constants, data structures, and functions used for handling capabilities in Linux. 
# Linux capabilities allow the kernel to grant finer-grained permissions to processes instead of using traditional user/group permissions.
cat /usr/include/linux/capability.h

# what network range are the nodes in the cluster part of?
# find internal IP of the nodes
ip a | grep eth0
# next, use ipcalc tool to see the network details:
ipcalc -b 192.14.41.6/24
        # Address:   192.14.41.6          
        # Netmask:   255.255.255.0 = 24   
        # Wildcard:  0.0.0.255            
        # =>
        # Network:   192.14.41.0/24       
        # HostMin:   192.14.41.1          
        # HostMax:   192.14.41.254        
        # Broadcast: 192.14.41.255        
        # Hosts/Net: 254          Class C
        
# Network:   192.14.41.0/24    is the ip range

# difference between "sudo -i" and "sudo -s"
sudo -i  # The -i option stands for "login shell." When you use sudo -i, it simulates a full login as the target user (by default, the root user). simulate a full login session for the target user, losing you current folder and setting
sudo -s  # The -s option stands for "shell." When you use sudo -s, it opens a shell with elevated privileges but retains the current user's environment and maintain your current environment settings and working directory.

# you are instructing the systemd system and service manager to reload its configuration files. This command is necessary when you have made changes to unit files (such as service files) or have added new ones, and 
# you want systemd to recognize these changes without having to reboot the system.
systemctl daemon-reload
# NO SERVICE RESTART: It's important to note that daemon-reload does not restart any running services. It only reloads the configuration. If you need to apply changes to a running service, you will need to restart or reload the 
# service separately using systemctl restart <service-name> or systemctl reload <service-name>, i.e:
systemctl daemon-reload
systemctl restart kubelet

# IPAM = IP Address Management, deals with the planning, tracking, and managing of IP address space within a network.
# IPAM is responsible for assigning IP addresses to pods in a Kubernetes cluster
# IP Address Allocation: Calico's IPAM is responsible for allocating IP addresses to pods when they are created. It ensures that each pod receives a unique IP address from a predefined IP pool.
# IP Pools: Calico allows you to define IP pools, which are ranges of IP addresses that can be used for pod networking. You can configure multiple IP pools and specify which pools should be used for different namespaces or workloads.
# IPAM Modes: Calico supports different IPAM modes, such as: Calico IPAM: The default mode, where Calico manages IP address allocation and ensures efficient use of IP address space , HostLocal IPAM: An alternative mode where IP addresses are allocated from a local range on each node, rather than a global pool.
