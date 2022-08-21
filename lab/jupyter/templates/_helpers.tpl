{{/*
Create a random string (different each time you call this function!) for Jupyter token - but only if one does not exist already
*/}}
{{- define "datasciencelab.jupyterToken" }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "common.names.fullname" .)) }}
{{- if .Values.jupyter.token }}
    {{- .Values.jupyter.token | b64enc }}
{{- else if $secret }}
    {{- index $secret.data "jupyterToken" }}
{{- else }}
    {{- randAlphaNum 64 | b64enc }}
{{- end }}
{{- end }}


{{/*
Secret for Postgresql, same logic
*/}}
{{- define "datasciencelab.postgres.postgres-password" }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (.Values.postgresql.auth.existingSecret | quote )) }}
{{- if $secret }}
    {{- index $secret.data "postgres-password" }}
{{- else }}
    {{- randAlphaNum 24 | b64enc }}
{{- end }}
{{- end }}

{{- define "datasciencelab.postgres.password" }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (.Values.postgresql.auth.existingSecret | quote )) }}
{{- if $secret }}
    {{- index $secret.data "password" }}
{{- else }}
    {{- randAlphaNum 24 | b64enc }}
{{- end }}
{{- end }}

{{- define "datasciencelab.postgres.replication-password" }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (.Values.postgresql.auth.existingSecret | quote )) }}
{{- if $secret }}
    {{- index $secret.data "replication-password" }}
{{- else }}
    {{- randAlphaNum 24 | b64enc }}
{{- end }}
{{- end }}


{{/*
Secret for MySQL, same logic
*/}}
{{- define "datasciencelab.mysql.root-password" }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (.Values.mysql.auth.existingSecret | quote )) }}
{{- if $secret }}
    {{- index $secret.data "root-password" }}
{{- else }}
    {{- randAlphaNum 24 | b64enc }}
{{- end }}
{{- end }}

{{- define "datasciencelab.mysql.password" }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (.Values.mysql.auth.existingSecret | quote )) }}
{{- if $secret }}
    {{- index $secret.data "password" }}
{{- else }}
    {{- randAlphaNum 24 | b64enc }}
{{- end }}
{{- end }}

{{- define "datasciencelab.mysql.replication-password" }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (.Values.mysql.auth.existingSecret | quote )) }}
{{- if $secret }}
    {{- index $secret.data "replication-password" }}
{{- else }}
    {{- randAlphaNum 24 | b64enc }}
{{- end }}
{{- end }}



{{/*
Compile all warnings into a single message, and call fail.
*/}}
{{- define "datasciencelab.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "datasciencelab.validateValues.namespacedefault" .) -}}
{{- $messages := append $messages (include "datasciencelab.validateValues.namespace" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION FAILED:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}



{{- define "datasciencelab.validateValues.namespacedefault" -}}
{{- if eq .Release.Namespace "default" }}
You are trying to install this helm chart into the Kubernetes default namespace "default".
Please choose a dedicated namespace, NOT "default"!

{{ end -}}
{{- end -}}



{{- define "datasciencelab.validateValues.namespace" -}}
{{- if ne .Values.namespace .Release.Namespace }}
You are trying to install this helm chart into the Kubernetes namespace "{{ .Release.Namespace }}",
but you set your myvalues.yaml/values.yaml key to

    namespace: {{ .Values.namespace }}

Both namespaces need to match!

{{ end -}}
{{- end -}}
