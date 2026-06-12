{{- with .Values.tolerations }}. does with work as loop here?

No. `with` is **not a loop** in Helm/Go templates.

`with` changes the current context (`.`) to the value you specify, but it only executes the block if that value is not empty.

Example:

```yaml
{{- with .Values.tolerations }}
tolerations:
{{ toYaml . | nindent 2 }}
{{- end }}
```

If `values.yaml` contains:

```yaml
tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
```

then inside the `with` block:

```yaml
.
```

becomes:

```yaml
.Values.tolerations
```

So:

```yaml
{{ toYaml . }}
```

is equivalent to:

```yaml
{{ toYaml .Values.tolerations }}
```

### `with` vs `range`

**with** (changes context)

```yaml
{{- with .Values.image }}
repository: {{ .repository }}
tag: {{ .tag }}
{{- end }}
```

Inside the block, `.` is `.Values.image`.



**range** (loops)

```yaml
{{- range .Values.tolerations }}
- key: {{ .key }}
  operator: {{ .operator }}
{{- end }}
```

Here Helm iterates over every item in the list.

### Important gotcha

Inside a `with`, you lose access to the original `.` unless you use `$`:

```yaml
{{- with .Values.image }}
repository: {{ .repository }}
chart: {{ $.Chart.Name }}
{{- end }}
```

* `.` → `.Values.image`
* `$` → root context (original `.`)

So `with` is best thought of as:

> "If this value exists, enter a new scope where `.` points to that value."

while `range` means:

> "Loop over each item in this collection."

---

Both `if` and `with` conditionally execute a block, but they serve different purposes.

### Use `if` when you only want to test a condition

```yaml
{{- if .Values.metrics.enabled }}
annotations:
  prometheus.io/scrape: "true"
{{- end }}
```

Here you're asking:

> "Is `metrics.enabled` true?"

The context (`.`) stays the same inside the block.


### Use `with` when you want to test a value **and** make it the new context

Instead of:

```yaml
{{- if .Values.image }}
image:
  repository: {{ .Values.image.repository }}
  tag: {{ .Values.image.tag }}
{{- end }}
```

you can write:

```yaml
{{- with .Values.image }}
image:
  repository: {{ .repository }}
  tag: {{ .tag }}
{{- end }}
```

Inside the block, `.` becomes `.Values.image`.


### Common Helm pattern

```yaml
{{- with .Values.nodeSelector }}
nodeSelector:
{{ toYaml . | nindent 2 }}
{{- end }}
```

This means:

1. If `.Values.nodeSelector` is not empty, render the block.
2. Inside the block, `.` refers to `.Values.nodeSelector`.

Using `if` here would be more verbose:

```yaml
{{- if .Values.nodeSelector }}
nodeSelector:
{{ toYaml .Values.nodeSelector | nindent 2 }}
{{- end }}
```

### Rule of thumb

* **`if`** → "Should I render this block?"
* **`with`** → "Should I render this block, and while I'm here, make this object my current context?"

For Kubernetes Helm charts, you'll very often see:

```yaml
{{- with .Values.annotations }}
{{- with .Values.nodeSelector }}
{{- with .Values.affinity }}
{{- with .Values.tolerations }}
```

because these are objects/lists that become easier to reference as `.` within the block.

---

`.Chart` and `.Release` are built-in Helm objects that Helm automatically provides when rendering templates.

## `.Chart`

Contains information from your `Chart.yaml`.

Example `Chart.yaml`:

```yaml
apiVersion: v2
name: retail-ui
version: 1.2.3
appVersion: "2.1.0"
description: Retail UI
```

You can access:

```yaml
{{ .Chart.Name }}
```

→ `retail-ui`

```yaml
{{ .Chart.Version }}
```

→ `1.2.3`

```yaml
{{ .Chart.AppVersion }}
```

→ `2.1.0`

Example:

```yaml
labels:
  helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
```

renders:

```yaml
labels:
  helm.sh/chart: retail-ui-1.2.3
```


## `.Release`

Contains information about the Helm release.

Suppose you run:

```bash
helm install my-shop ./chart
```

Then:

```yaml
{{ .Release.Name }}
```

→ `my-shop`

```yaml
{{ .Release.Namespace }}
```

→ namespace where it is installed

```yaml
{{ .Release.Service }}
```

→ usually `Helm`

Example:

```yaml
metadata:
  name: {{ .Release.Name }}
```

renders:

```yaml
metadata:
  name: my-shop
```


## Why do charts use `.Release.Name`?

To allow multiple installations of the same chart.

For example:

```bash
helm install dev-retail ./chart
helm install prod-retail ./chart
```

Then:

| Release | `.Release.Name` |
| ------- | --------------- |
| Dev     | `dev-retail`    |
| Prod    | `prod-retail`   |

The chart can generate unique resource names:

```yaml
metadata:
  name: {{ .Release.Name }}-ui
```

Result:

```yaml
dev-retail-ui
prod-retail-ui
```


## Common objects you'll see

```yaml
.Values
```

Values from `values.yaml`

```yaml
.Chart
```

Metadata from `Chart.yaml`

```yaml
.Release
```

Information about the Helm installation/upgrade

```yaml
.Capabilities
```

Kubernetes version and supported APIs

```yaml
.Files
```

Access files packaged in the chart


When you see something like:

```yaml
app.kubernetes.io/instance: {{ .Release.Name }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
```

it's using:

* `.Release.Name` → identifies **this installation** of the chart
* `.Chart.Name` / `.Chart.Version` → identifies **the chart package itself**.

---

{{ ... }}   keep surrounding whitespace

{{- ... }}  trim whitespace before the tag

{{ ... -}}  trim whitespace after the tag

{{- ... -}} trim both sides
