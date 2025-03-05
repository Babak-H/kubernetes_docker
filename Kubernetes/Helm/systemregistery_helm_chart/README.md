
dbie-gke is our chart, inside it we have
- templates => this folder contains all the original kubernetes files that are turned into helm templates, they are written in GoLang templating language (similar to Jinja)
- Chart.yaml => this file contains the information about this chart
- values.yaml => contains default values for this chart, values will be injected to the template file

outside the chart we have:
- values folder => inside it we have values file for each instance of the chart, these will replace the variables of values.yaml file that is inside the chart.
- helmfile.yml => here we define each instance of the chart and where it's values are located.


# useful Helm commands

### generates all base files needed for a helm chart, microservice can be changed to any name for the chart
helm create microservice  

### this will inject the values into the chart to make sure that it works correctly
helm template -f values/test-values.yml microservice  
### checks the yaml file's syntaxt for both values file and helm template files
helm lint -f values/test-values.yml microservice

### install the chart into the cluster, this should be done for each microserivce that wants to be added into the cluster based on the chart
helm install -f values/test-values.yml CutomName microservice

### same as above, but this one injects values to kubernetes cluster temporarily to make sure it works fine
helm install --dry-run -f values/test-values.yml microservice

### shows all microservices running
helm ls

### unistall helm services
helm uninstall CutomName

### install helmfile tool, this is a plugin for Helm, allows installing several instances of the chart at once
brew install helmfile

### deploy helm charts via helmfile
helmfile sync

### shows all the applied charts
helmfile list

### delete all the service
helmfile destroy


## install metric server: 
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm upgrade --install metrics-server metrics-server/metrics-server

## install kube-state-metrics:
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kubestatemetrics prometheus-community/kube-state-metrics
