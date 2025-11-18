# In a Helm chart, _helpers.tpl is a template file that contains reusable template snippets (often called “template helpers”).
# These helpers are functions or small template blocks that you can call from other chart templates (e.g., Deployment, Service, Ingress).
# it helps to Avoid repeating the same logic or labels everywhere and Build consistent names or annotations

# _helpers.tpl is It’s a file under templates/ directory, It almost always starts with an underscore _ so Helm does not render it as a manifest.

# It defines named templates using:
  # {{- define "mychart.name" -}}
  # ...
  # {{- end -}}

# These helpers can then be called elsewhere:
  # {{ include "mychart.name" . }

# this is a comment explaining how this function works
{{ /* Return the full name of the chart, including name override logic. */ }}
# name the function
{{- define "myapp.fullname" -}}

# the logic inside the function, if condition is met, return one value, otherwise another value
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

# end the function
{{- end }}

{{/* Common labels used across all resources. */}}
{{- define "myapp.labels" -}}
# here we call the fuction that was defined above
app.kubernetes.io/name: {{ include "myapp.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Selector labels for Deployments, Services, etc. */}}
{{- define "myapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "myapp.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


---
# how to use helper functions in deployment file
apiVersion: apps/v1
kind: Deployment
metadata:
  # call function from helpers
  name: {{ include "myapp.fullname" . }}
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "myapp.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "myapp.selectorLabels" . | nindent 8 }}
