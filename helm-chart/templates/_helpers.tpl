{{- define "skil2-2-voorbeeldproject3.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "skil2-2-voorbeeldproject3.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}
