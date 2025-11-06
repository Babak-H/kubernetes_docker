{{/* vim: set filetype=mustache: */}}

{{- define "vault.topic-def" -}}
  name: {{ .name }}
{{- if hasKey . "replicationfactor" }}
  replication.factor: {{ .replicationfactor }}
{{- end }}
{{- if hasKey . "properties" }}
  properties:
    {{- .properties | toYaml | nindent 4 -}}
{{- end }}
{{- if hasKey . "partitions" }}
  partitions: {{ .partitions -}}
{{- end }}
  producers:
    - name: vault-operator
{{- if hasKey . "producers" }}
    {{- .producers | toYaml | nindent 4 -}}
{{- end }}
{{- if and (hasKey . "testProducers") (ne "pcore" .environment) }}
    {{- .testProducers | toYaml | nindent 4 -}}
{{- end }}
  consumers:
    - name: vault-operator
{{- if hasKey . "consumers" }}
    {{- .consumers | toYaml | nindent 4 -}}
{{- end }}
{{- if and (hasKey . "testConsumers") (ne "pcore" .environment) }}
    {{- .testConsumers | toYaml | nindent 4 -}}
{{- end }}
{{- end -}}