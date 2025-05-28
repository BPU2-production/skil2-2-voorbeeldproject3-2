{{- define "skil2-2-voorbeeldproject3.name" -}}
{{ .Chart.Name }}
{{- end }}

# {{- define "skil2-2-voorbeeldproject3.db.name" -}}
# {{ .Chart.Name }}-db
# {{- end }}

{{- define "skil2-2-voorbeeldproject3.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}

# {{- define "skil2-2-voorbeeldproject3.db.fullname" -}}
# {{ .Release.Name }}-{{ .Chart.Name }}-db
# {{- end }}
