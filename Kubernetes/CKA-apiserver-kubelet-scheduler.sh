# kube-apiserver => heart of the kubernetes, connects all systems together
# etcd => key-value database that keeps the latest value for different cluster related varialbes (how many nodes, how many pods, secrets, configmaps,...)
# controller-manager => manages all controllers (deployment controller, pod controller, volume controller,...)
# kube-scheduler => schedule which pod on which node
# kube-proxy => creates services to connect pods together

# kube-apiserver => 6443
# kubelet => 10250  /var/lib/kubelet/
# kube-scheduler => 10251
# kube-controller-manager => 10252
# etcd => 2379-2380

# kubeadm => /etc/kubernetes/admin.conf
# CNI => /etc/cni/inet.d/
# static pods => /etc/kubernetes/manifests/

############################################## Kube-ApiServer

# if there is a problem with kube-apiserver we can't access kubectl
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
vi /etc/kubernetes/manifests/kube-apiserver.yaml
systemctl daemon-reload

# Determine the Service CIDR range used by the cluster.
k get po kube-apiserver-xxx-xxx -n kube-system -o yaml | grpe -i "service-cluster-ip-range"  # - --service-cluster-ip-range=10.96.0.0/12

# accessing all containers when kube-apiserver is down 
crictl ps
# accessing all container logs when kube-apiserver is down 
crictl logs <CONTAIMER-ID>
# delete a container by it's ID
crictl rm <CONTAIMER-ID>
# delete a image by its id
crictl rmi <IMAGE-ID>
# find the runtimeType of the running container
crictl inspect <CONTAIMER-ID> | grep runtimeType  # "runtimeType": "io.containerd.runc.v2"



# How many controlplane nodes are available?, How many worker nodes are available?
k get nodes -o wide  # see the worker nodes and controlplane nodes

# What is the Service CIDR? => ssh into master node 
cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep "service-cluster-ip-range" # or just "grep range", service CIDR

# Which Networking (or CNI Plugin) is configured and where is its config file?
ls -la /etc/cni/net.d/
# /etc/cni/net.d/
# /etc/cni/net.d/10-weave.conflist

cat /etc/cni/net.d/10-weave.conflist
# {
#     "cniVersion": "0.3.0",
#     "name": "weave",

# Which suffix (ending) will static pods have that run on cluster1-node1?
# The suffix is the node's hostname with a leading hyphen =>  "-cluster1-node1"

############################################## Kubelet

# kubelet configuration file locations:
# easiest way to find it
systemctl status kubelet # find the section called "Drop-In", the kubelet file to edit is in that folder

# deploy a pod on node01 as per specifiction: name: web-pod | container-name: web | image: nginx (there will be problems here related to cluster)
k run web-pod --image=nginx --dry-run=client -o yaml > pod.yaml
vi pod.yaml # change the container name
k apply -f pod.yaml
k get pods # we can see pods is in pending state
k get nodes # node01 is NOT ready
ssh node01
sudo -s
systemctl status kubelet
systemctl start kubelet  # ExecStart=/usr/bin/local/kubelet => normally kubelet exec file should NOT be in local folder, instead at "/usr/bin/kubelet"
journalctl -u kubelet -n 20 # check the logs, last 20 lines
# error related to address of kubelet
        # kubelet.service: Failed to locate executable /usr/etc/kubelet: No such file or directory
        # kubelet.service: Failed at step EXEC spawning /usr/etc/kubelet: No such file or directory
        
ls /usr/bin/local/kubelet   # does not exist
which kubelet # shows correct address for kubelet service executable
vi /etc/systemd/system/kubelet.service.d/10-kubeadm.conf  # go to folder where kubelet executable is located at
# edit this line
  ExecStart=/usr/bin/kubelet
  
systemctl daemon-reload
systemctl start kubelet
systemctl kubelet status
exit
k get nodes
k get po web-pod

# A Kubernetes worker node, named wk8s-node-0 is in state NotReady. Investigate why this is the case, and perform any appropriate steps to bring the node to a Ready state, 
# ensuring that any changes are made permanent
k get nodes 
k describe nodes wk8s-node-0  # kubelet stopped sending status, Node status unknown
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

echo 'journalctl -u kubelet' > /home/ubuntu/kubelet.sh

############################################## Scheduler

echo 'kubectl logs kube-scheduler-ip-10-0-0-100.us-west-2.compute.internal -n kube-system' > /home/ubuntu/scheduler.sh

# how to stop kube-scheduler => either move the pod to another folder outside manifests OR just comment some parts of it
# check 
k get po -n kube-system | grep scheduler  # can't see it now

# adding "nodeName" to ".spec" of a pod, manually schedules it on a Node, even if kube-scheduler is down
# The only thing a scheduler does, is that it sets the nodeName for a Pod declaration
# Only the scheduler takes tains/tolerations/affinity into account when finding the correct node name. That's why it's still possible to assign Pods manually directly to a controlplane node and skip the scheduler

apiVersion: v1
kind: Pod
metadata:
  labels:
    run: manual-schedule
  name: manual-schedule
  namespace: default
spec:
  # nodeName: NAME-OF-SPECIFIC-NODE
  nodeName: cluster2-controlplane1        
  containers:
  - image: httpd:2.4-alpine
    name: manual-schedule


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

############################################## Controller-Manager

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
