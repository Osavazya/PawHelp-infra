{{- define "crm-manager.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "crm-manager.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "crm-manager.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "crm-manager.labels" -}}
app.kubernetes.io/name: {{ include "crm-manager.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}