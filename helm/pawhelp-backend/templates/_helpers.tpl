{{- define "pawhelp-backend.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pawhelp-backend.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "pawhelp-backend.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pawhelp-backend.labels" -}}
app.kubernetes.io/name: {{ include "pawhelp-backend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

