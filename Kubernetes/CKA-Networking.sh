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
ps aux

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

# unlock the certificate file/public key of type x509 encryption
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout

# Key-file : private key  |  cert-file : public key | trusted-ca-file : public key from CA

# Certificate Authority:
# generate private key
openssel genrsa -out ca.key 2048  # ca.key
# certificate signing request
openssl req -new -key ca.key -subj “/CN=KUBERNETES-CA” -out ca.csr   # ca.csr  
# generate public key for CA, we will use this key to send it to the server that we send request to, so that it can be sure the request is signed by correct CA
openssl x509 -req -in ca.csr -signkey ca.key -out ca.crt  # ca.crt

Admin user
# generate private key
openssl genrsa -out admin.key 2048  # admin.key
# certificate signing request
openssl req -new -key admin.key -subj “\CN=kube-admin/OU=system:masters” -out admin.csr # admin.csr
# here we use the public and private keys from certificate authority, and sign the request
openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -out admin.crt

# Kube-scheduler, kube-controller-manager, kube-proxy
# Generate keys
# Certificate signing request
# Sign certificates and generate public key

# Kube-api-server:
# generate private key
openssl genrsa -out apiserver.key 2048
# certificate signing request, use the private key
openssl req -key apiserver.key -subj “/CN=kube-apiserver” -out apiserver.csr -config openssl.cnf
# here we use the public and private keys from certificate authority, and sign the request
openssl x509 -req -in apiserver.csr -CA ca.crt -CAkey ca.key -out apiserver.crt

# difference between "sudo -i" and "sudo -s"
sudo -i  # The -i option stands for "login shell." When you use sudo -i, it simulates a full login as the target user (by default, the root user). simulate a full login session for the target user, losing you current folder and setting
sudo -s  # The -s option stands for "shell." When you use sudo -s, it opens a shell with elevated privileges but retains the current user's environment and maintain your current environment settings and working directory.
