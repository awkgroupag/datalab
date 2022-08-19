{{/*
Create a random string (different each time you call this function!) for this value - but only if one does not exist already
*/}}
{{- define "datasciencelab.airflow.airflow-fernet-key" }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace ("airflow")) }}
{{- if $secret }}
    {{- index $secret.data "airflow-fernet-key" }}
{{- else }}
    {{- randAlphaNum 64 | b64enc }}
{{- end }}
{{- end }}



{{- define "datasciencelab.airflow.airflow-password" }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace ("airflow")) }}
{{- if $secret }}
    {{- index $secret.data "airflow-password" }}
{{- else }}
    {{- randAlphaNum 16 | b64enc }}
{{- end }}
{{- end }}


{{- define "datasciencelab.airflow.airflow-secret-key" }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace ("airflow")) }}
{{- if $secret }}
    {{- index $secret.data "airflow-secret-key" }}
{{- else }}
    {{- randAlphaNum 64 | b64enc }}
{{- end }}
{{- end }}



{{- define "datasciencelab.airflow.postgresql-password" }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace ("airflow")) }}
{{- if $secret }}
    {{- index $secret.data "postgresql-password" }}
{{- else }}
    {{- randAlphaNum 16 | b64enc }}
{{- end }}
{{- end }}


{{- define "datasciencelab.airflow.redis-password" }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace ("airflow")) }}
{{- if $secret }}
    {{- index $secret.data "redis-password" }}
{{- else }}
    {{- randAlphaNum 64 | b64enc }}
{{- end }}
{{- end }}
