{{/*
Return the namespace used by namespaced resources
*/}}
{{- define "springboot-microservice.namespace" -}}
{{- default .Release.Namespace .Values.namespace.name -}}
{{- end -}}

{{/*
Common chart labels
*/}}
{{- define "springboot-microservice.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: springboot-microservice
{{- end -}}
