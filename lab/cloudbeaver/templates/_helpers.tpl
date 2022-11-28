{{/*
Create a random string (different each time you call this function!) for Jupyter token - but only if one does not exist already
*/}}
{{- define "cloudbeaver.adminpassword" }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "common.names.fullname" .)) }}
{{- if $secret }}
    {{- index $secret.data "CB_ADMIN_PASSWORD" | b64dec }}
{{- else }}
    {{- randAlphaNum 16 }}
{{- end }}
{{- end }}



{{/*
Compile all warnings into a single message, and call fail.
*/}}
{{- define "cloudbeaver.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "cloudbeaver.validateValues.namespacedefault" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION FAILED:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}


{{- define "cloudbeaver.validateValues.namespacedefault" -}}
{{- if eq .Release.Namespace "default" }}
You are trying to install this helm chart into the Kubernetes default namespace "default".
Please choose a dedicated namespace, NOT "default"!

{{ end -}}
{{- end -}}
