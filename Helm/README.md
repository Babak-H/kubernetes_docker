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

---

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

---

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

---

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

---

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
