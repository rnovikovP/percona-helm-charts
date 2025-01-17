{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "postgres-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "postgres-operator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "postgres-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "postgres-operator.labels" -}}
helm.sh/chart: {{ include "postgres-operator.chart" . }}
{{ include "postgres-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
meta.helm.sh/release-name: {{ .Release.Name }}
meta.helm.sh/release-namespace: {{ .Release.Namespace }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "postgres-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "postgres-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "postgres-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default "pgo-deployer-sa" .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the template for image pull secrets
*/}}
{{- define "postgres-operator.imagePullSecret" -}}
{{- if ne .Values.pgo_image_pull_secret "" }}
imagePullSecrets:
- name: "{{ .Values.pgo_image_pull_secret }}"
{{ end }}
{{ end }}

{{/*
Create the template for clusterroleName based on values.yaml parameters
*/}}
{{- define "postgres-operator.clusterroleName" -}}
{{- if .Values.rbac.useClusterAdmin -}}
cluster-admin
{{- else -}}
{{ include "postgres-operator.fullname" . }}-cr
{{- end }}
{{- end }}

{{/*
Generate Configmap based on Values defined in values.yaml
*/}}
{{- define "postgres-operator.values" -}}
{{- $namespace := .Release.Namespace -}}
{{- $namespace_fields := list "namespace" "pgo_operator_namespace" }}
{{- $ignore_fields := list "fullnameOverride" "rbac" "serviceAccount" "disableFSGroup" }}
values.yaml: |
  ---
{{- range $index, $value := .Values }}
{{- if not (has $index $ignore_fields) }}
{{- if has $index $namespace_fields }}
{{ $index | indent 2 }}: {{ $namespace | quote }}
{{- else if eq $index "pgo_image_tag" }}
{{ $index | indent 2 }}: {{ $.Chart.AppVersion | quote }}
{{- else if eq $index "ccp_image_tag" }}
{{ $index | indent 2 }}: "{{ $.Chart.AppVersion }}-postgres-ha"
{{- else if eq $index "disable_fsgroup" }}
{{ $index | indent 2 }}: "{{ $.Values.disableFSGroup }}"
{{- else }}
{{ $index | indent 2 }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
