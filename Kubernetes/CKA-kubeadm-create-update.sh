# Given an existing Kubernetes cluster running version 1.30.1, upgrade all of the Kubernetes controlplane and node components ONLY on the master node to version 1.30.1
# Be sure to drain the master node before upgrading it and uncordon it after the upgrade
# You are also expected to upgrade kubelet and kubectl on the master node, do NOT upgrade the worker nodes, etcd, the containerv manager, the CNI plugins or the DNS service

k cordon master
k drain master --ignore-daemonsets
k get nodes  # make sure its drained and unschedulable
ssh master
sudo -s
# start the upgrade process
apt update
apt-cache madison kubeadm | grep "1.30" # display detailed information about a specific package available in the APT package repository on Debian-based systems, showing it's different versions | find correct version
apt-mark unhold kubeadm  # when you are ready to upgrade kubeadm to newer versions manually, you can unlock the old, basically un-freezing package version
apt-get install -y kubeadm=1.30.1-1.1 # -y flag => automatically answer "yes" to any prompts that might appear during the installation process, allowing running the command from a script
kubeadm version -o short
apt-mark hold kubeadm # prevent the specified packages (kubeadm here) from being automatically upgraded when you run system updates, freezes package version
kubeadm upgrade plan
kubeadm upgrade apply v1.30.1-1.1 --etcd-upgrade=false --skip-phases=addon/coredns
# upgrade kubectl and kubelet on master node
apt-mark unhold kubelet kubectl 
apt-get update
apt-get install -y kubelet=1.30.1-1.1 kubectl=1.30.1-1.1
kubectl version 
kubelet --version
apt-mark hold kubelet kubectl
systemctl daemon-reload
systemctl restart kubelet
exit
k uncordon master
k get nodes  # should be ready and schedulable


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
apt-cache madison kubeadm | grep "1.30"  # this step is NOT required if you are upgrading both master and worker nodes, just use same exact version as masternode
apt-mark unhold kubeadm
apt-get install -y kubeadm=1.30.1-1.1
kubeadm version -o short
apt-mark hold kubeadm
kubeadm upgrade node  # only change is here
apt-mark unhold kubelet kubectl 
# you CAN NOT check the node version here, do it at end on controlplane node
apt-get update
apt-get install -y kubectl=1.30.1-1.1 kubelet=1.30.1-1.1
kubectl version 
kubelet --version
apt-mark hold kubectl kubelet
systemctl daemon-reload
systemctl restart kubelet
exit
k uncordon worker-node-3
k get nodes

# if the worker node has NOT joined the cluster, running "kubeadm upgrade node" will result in error


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
# RE-RUN the KUBEADM JOIN AGAIN, IF KUBELET WAS NOT ACTIVE ?
exit
ssh controlplane
k get nodes
# just for testing
k run web --image=nginx
k get po


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


# install docker on nodes for kubertnets installation
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce
sudo systemctl status docker
sudo docker run hello-world
