{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "datasciencelab.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate to 20 characters because this is used to set the node identifier in WildFly which is limited to
23 characters. This allows for a replica suffix for up to 99 replicas.
*/}}
{{- define "datasciencelab.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 20 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 20 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 20 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "datasciencelab.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "datasciencelab.labels" -}}
helm.sh/chart: {{ include "datasciencelab.chart" . }}
app.kubernetes.io/version: {{ .Values.jupyter.image.tag | default .Chart.AppVersion | trunc 63 | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "datasciencelab.selectorLabels" -}}
app.kubernetes.io/name: {{ include "datasciencelab.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create a default fully qualified app name for the postgres requirement.
*/}}
{{- define "datasciencelab.postgresql.fullname" -}}
{{- $postgresContext := dict "Values" .Values.postgresql "Release" .Release "Chart" (dict "Name" "postgresql") -}}
{{ include "datasciencelab.fullname" .}}-{{ include "postgresql.name" $postgresContext }}
{{- end }}

{{/*
Create a secret - but only if one does not exist already
*/}}
{{- define "datasciencelab.jupyterToken" }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "datasciencelab.fullname" .)) }}
{{- if $secret }}
{{- index $secret.data "jupyterToken" }}
{{- else }}
{{- randAlphaNum 64 | b64enc }}
{{- end -}}
{{- end -}}
