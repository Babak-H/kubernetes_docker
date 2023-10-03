# install helm chart
helm install prometheus stable/prometheus-operator

# the operator arguments and mounts
# mounts => where prometheus gets all its configuration data
kubectl get statefulset

kubectl describe statefulset prometheus-prometheus-prometheus-oper-prometheus > prometheus-operator.yml

cat prom.yml

# grafana is using clusterIP by default, we can use port forwarding to access it from outside the cluster
kubectl get pod 3 find name of the pod where grafana is runnig on

# open the logs for grafana pod and check which port it is listening on 
kubectl logs <GRAFANA-POD_ID> -c grafana

# port forwad so we can access it from outside cluster
kubectl port-forward deployment/prometheus-grafana 3000

# user/pass for grafana login can be found on the helm charts github page


