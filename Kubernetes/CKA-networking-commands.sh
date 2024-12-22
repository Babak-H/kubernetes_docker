############################################## CoreDNS, DNS, CNI

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
