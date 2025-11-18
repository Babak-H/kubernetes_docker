# deploy redis and nodejs applications (we will scrape thess applications later)
k apply -f redis.yml
k apply -f node-app.yml

# use these commands to add prometheus operator helm chart (which includes all needed services) to the cluster
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# update the repository
helm repo update

# create prometheus cluster in its own namespace. so it won't be mixed we the main cluster
k create namespace monitoring

# install the prometheus stack
# -n at the end specifies the name space to install it
# local name => monitoring
# repo name => prometheus-community/kube-prometheus-stack
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring

# show the installed charts
helm ls -n monitoring
# here we can see all the deployments related to prometheus-grafana and also statefulsets related to alertManager and prometheus (its database for saving metrics)
k get all -n monitoring

# get all the configmaps related to the prometheus stack
k get configmap -n monitoring

# automatically generated secrets of the cluster (certificates, user/pass,..)
k get secret -n monitoring

# the Custom Resource Definitions (CRD) for the cluster (an extention from prometheus to add more functionality, such as ServiceMonitor resource)
k get crd -n monitoring

# view the prometheus statefulSet configurations (converted to YAML file)
k describe statefulset prometheus-monitoring-kube-prometheus-prometheus -n monitoring > prom.yml

# view the prometheus operator configurations
# we also have "config-reloader" sidecar container here, it forces prometheus to reload each time we change some configuration
k describe deployment monitoring-kube-prometheus-operator -n monitoring > oper.yml

 # prometheus operator extends the Kubernetes API => 
    # we create custom kubernetes resources CR => 
      # operator takes our custom resources and tells prometheus to reload its alert rules

# **** by default prometheus will scrape endpoints for all the pods/deployments in all namespaces (including itself) 
# as long as those namespaces having the /metric endpoint exposed (or having some sort of exporter)

# here we create a new deployment to test our cpu and memory usage
k run cpu-test --image=containerstack/cpustress -- --cpu 4 --timeout 30s --metric-brief

# prometheus stacks comes with a list of already applied Alerts that can be triggered, but we can also add extra alerts to the stack through yaml configuration files
# normally we should only write new alert rules to the main alerts files of prometheus, but because we are running it through kubernetes, we can create alerts in the form of CRDs and add them to the prometheus operator
# apply prometheus alert_rules file
k apply -f alert_rules.yml

# check to see the object is created (shows all existing prometheus rules)
k get PrometheusRule -n monitoring

# alertmanager is its own application, and has a config file separate from prometheus
# this is our original alert manager  configuration file
k get secret alertmanager-monitoring-kube-prometheus-alertmanager-generated -n monitoring -o yaml
 
# apply the alert manager config file (for sending alert emails) after this users should receive alert emails in case of the alert rules apply
# this is also a kubernetes CRD that we apply to alertmanager operator, it adds the new config to already existing alertmanager
k apply -f email-secret.yaml
k apply -f alert-manager-configuration.yaml

# view the CRD created for alertmanager
k get alertmanagerconfig -n monitoring

# reload the configuration for alert-manager
# alertmanager-monitoring-kube-prometheus-alertmanager-0 => name of the alertmanager pod
k logs alertmanager-monitoring-kube-prometheus-alertmanager-0 -n monitoring -c config-reloader

# by default we have several service monitors (needed for exporters) enabled in prom cluster
k get servicemonitor -n monitoring

# to monitor the REDIS database inside our cluster we need extra packages to connect prometheus to redis endpoint since prometheus can't directly read redis logs
# this is called "Exporter", we use redis-exporter helm chart
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install redis-exporter prometheus-community/prometheus-redis-exporter -f redis-values.yml

# the pod "redis-exporter-prometheus-redis-exporter" should be running
k get pod

# apply redis alert rules file
k apply -f redis-rules.yml

# how to send metrics from custom application to prometheus:
# 1. expose metrics for the app via using prom client library in the app and exposing metrics on /metric endpoint
# 2. deploy app to the cluster
# 3. *** Configure prometheus to Scrape new target (using ServiceMonitor) ***

# create the serviceMonitor,so that prometheus can scrape our NodeJS app
k apply -f node-service-monitor.yml