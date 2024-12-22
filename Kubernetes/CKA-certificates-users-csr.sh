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
