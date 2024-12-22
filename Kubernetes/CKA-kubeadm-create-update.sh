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
