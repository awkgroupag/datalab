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
{{- printf .Release.Name | trunc 20 | trimSuffix "-" }}
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
app.kubernetes.io/name: {{ .Chart.Name | quote }}
app.kubernetes.io/instance: {{ include "datasciencelab.fullname" . | quote }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "datasciencelab.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name | quote }}
app.kubernetes.io/instance: {{ include "datasciencelab.fullname" . | quote }}
{{- end }}

{{/*
Create a default fully qualified app name for the postgres requirement.
*/}}
{{- define "datasciencelab.postgresql.fullname" -}}
{{- $postgresContext := dict "Values" .Values.postgresql "Release" .Release "Chart" (dict "Name" "postgresql") -}}
{{ include "datasciencelab.fullname" .}}-{{ include "postgresql.name" $postgresContext }}
{{- end }}


{{/*
Create a random string (different each time you call this function!) for Jupyter token - but only if one does not exist already
*/}}
{{- define "datasciencelab.jupyterToken" }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "datasciencelab.fullname" .)) }}
{{- if .Values.jupyter.token }}
    {{- .Values.jupyter.token | b64enc }}
{{- else if $secret }}
    {{- index $secret.data "jupyterToken" }}
{{- else }}
    {{- randAlphaNum 64 | b64enc }}
{{- end }}
{{- end }}

{{/*
Renders a value that contains template.
Usage:
{{ include "datasciencelab.rendertemplate" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "datasciencelab.rendertemplate" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}
