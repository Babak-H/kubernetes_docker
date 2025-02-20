# analyze and document all X509 certificates currently being used within the provided cluster using just the kubeadm tool
# update and renew the expiry date within the TLS certificate used by the Kubernetes API server
ssh controlplane
sudo -s
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

# Using kubeadm, read out the expiration date of the apiserver certificate and write it into /root/apiserver-expiration
kubeadm certs check-expiration | grep apiserver
echo "Dec 06, 2025 09:13 UTC" > /root/apiserver-expiration

#  Using kubeadm, renew the certificates of the apiserver and scheduler.conf
kubeadm certs renew apiserver
kubeadm certs renew scheduler.conf
# renew all
kubeadm certs renew all

# how to manually check the certificate start time and expiration date
openssl x509 -noout -text -in /etc/kubernetes/pki/apiserver.crt

# Create a new user called john. Grant him access to the cluster. John should have permission to create, list, get, update and delete pods in the development namespace. 
# The private key exists in the location: /root/CKA/john.key and csr at /root/CKA/john.csr
# https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#create-certificatessigningrequest

cat /root/CKA/john.csr | base64 | tr -d "\n"  # copy the encrypted value value
# create the certificate signing request file and apply it
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: john
spec:
  request: ...
  # Please note that an additional field called signerName should also be added when creating CSR.
  # For client authentication to the API server we will use the built-in signer "kubernetes.io/kube-apiserver-client"
  signerName: https://kubernetes.io/kube-apiserver-client
  usage: 
  - client auth 
        
k create -f csr.yaml
k get csr # john should be pending
k certificate approve john
k get csr # john should be approved

k create role developer -verb=create,list,get,update,delete --resource=pods -n development
k create rolebinding dev-john-role --role=developer --user=john -n development  # bound Role developer to user john
k auth can-i get pods --as=john -n development

# associate a serviceAccount with a deployment
k set serviceaccount deploy/web-dashboard dashboard-sa
# for pod
k set serviceaccount my-po my-serviceaccount

# kubelet client certificate (the one used for outgoing connections to the kube-apiserver)
ssh worker-node-1
sudo -s
ls /var/lib/kubelet/pki/
cat /var/lib/kubelet/pki/kubelet-client-current.pem  # its location can be found in kubeconfig file that kubelet use to connect to controlplane at ~/.kube/...
openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet-client-current.pem
# kubelet server certificate ( the one used for incoming connections from the kube-apiserver, public-key of kube-apiserver), located at same folder as client pem file
cat /var/lib/kubelet/pki/kubelet.crt
openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet.crt


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
# here we use the public and private keys from certificate authority, and sign the request
openssl x509 -req -in apiserver.csr -CA ca.crt -CAkey ca.key -out apiserver.crt


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

# The path to certificate is incorrect in the kubeconfig file. Correct the certificate name which is available at /etc/kubernetes/pki/users/
# Inspect the environment and identify the authorization modes configured on the cluster.
k describe pod kube-apiserver-controlplane -n kube-system | grep auth
#  --authorization-mode=Node,RBAC
