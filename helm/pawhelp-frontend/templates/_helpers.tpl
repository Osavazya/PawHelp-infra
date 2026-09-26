{{- define "pawhelp-frontend.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pawhelp-frontend.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "pawhelp-frontend.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pawhelp-frontend.labels" -}}
app.kubernetes.io/name: {{ include "pawhelp-frontend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

