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
