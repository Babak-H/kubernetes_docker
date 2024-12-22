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

# schedule a pod ONLY on controlplane node => node selector (label) + tiant-toleration (taints)
k get node
k describe node cluster1-controlplane1 | grep Taint -A1 # node-role.kubernetes.io/control-plane:NoSchedule
k get node cluster1-controlplane1 --show-labels # node-role.kubernetes.io/control-plane: ""
k run pod1 --image=httpd:2.4.41-alpine --dry-run=client -o yaml > 2.yaml

apiVersion: v1
kind: Pod
metadata:
  labels:
    run: pod1
  name: pod1
spec:
  containers:
  - image: httpd:2.4.41-alpine
    name: pod1-container
  # toleration allows the pod to run on the controlplane
  tolerations:                                 
  - effect: NoSchedule                         
    key: node-role.kubernetes.io/control-plane 
  # nodeselector chooses the pod based on the label
  nodeSelector:                                
    node-role.kubernetes.io/control-plane: ""  
