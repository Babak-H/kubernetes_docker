Here are **15 common Kubernetes errors** you should know for an SRE interview, with **short cause + fix**.

---

## 1. `CrashLoopBackOff`

**Meaning:** Pod starts, crashes, Kubernetes keeps restarting it.

**Common causes:**

* App bug
* Bad config/env variable
* Missing secret/configmap
* Wrong command/entrypoint

**Check:**

```bash
kubectl logs <pod>
kubectl describe pod <pod>
kubectl logs <pod> --previous
```

**Fix:** Read logs, fix app/config, then redeploy.

---

## 2. `ImagePullBackOff`

**Meaning:** Kubernetes cannot pull the container image.

**Common causes:**

* Wrong image name/tag
* Private registry auth issue
* Image does not exist

**Check:**

```bash
kubectl describe pod <pod>
```

**Fix:** Correct image name/tag or fix image pull secret.

---

## 3. `ErrImagePull`

**Meaning:** Initial image pull failed.

**Difference from `ImagePullBackOff`:** `ErrImagePull` happens first; after retries, it becomes `ImagePullBackOff`.

**Fix:** Same as above: verify image, registry, credentials.

---

## 4. `CreateContainerConfigError`

**Meaning:** Kubernetes cannot create the container because configuration is invalid.

**Common causes:**

* Missing ConfigMap
* Missing Secret
* Invalid env reference
* Bad volume mount

**Check:**

```bash
kubectl describe pod <pod>
```

**Fix:** Create/fix the missing Secret, ConfigMap, or volume reference.

---

## 5. `CreateContainerError`

**Meaning:** Container creation failed after config was accepted.

**Common causes:**

* Bad command
* Invalid volume mount
* Permission issue
* Runtime problem

**Check:**

```bash
kubectl describe pod <pod>
kubectl logs <pod>
```

**Fix:** Fix command, permissions, mount path, or runtime issue.

---

## 6. `Pending`

**Meaning:** Pod is not scheduled onto a node.

**Common causes:**

* Not enough CPU/memory
* Node selector mismatch
* Taints/tolerations issue
* PVC not bound

**Check:**

```bash
kubectl describe pod <pod>
kubectl get nodes
```

**Fix:** Add capacity, reduce resource requests, fix selectors/tolerations, or fix PVC.

---

## 7. `OOMKilled`

**Meaning:** Container used more memory than its limit and was killed.

**Check:**

```bash
kubectl describe pod <pod>
kubectl top pod <pod>
```

**Fix:** Increase memory limit, fix memory leak, or tune app memory usage.

---

## 8. `Evicted`

**Meaning:** Node removed the pod because of resource pressure.

**Common causes:**

* Node memory pressure
* Disk pressure
* PID pressure

**Check:**

```bash
kubectl describe pod <pod>
kubectl describe node <node>
```

**Fix:** Free node resources, clean disk, add capacity, or adjust requests/limits.

---

## 9. `RunContainerError`

**Meaning:** Kubernetes created the container but failed to start it.

**Common causes:**

* Bad startup command
* Missing executable
* Permission denied
* Bad volume mount

**Check:**

```bash
kubectl describe pod <pod>
kubectl logs <pod>
```

**Fix:** Fix container command, permissions, or mounted files.

---

## 10. `NodeNotReady`

**Meaning:** Kubernetes node is unhealthy or unreachable.

**Common causes:**

* Kubelet down
* Network issue
* Disk pressure
* Container runtime problem

**Check:**

```bash
kubectl get nodes
kubectl describe node <node>
systemctl status kubelet
```

**Fix:** Restart kubelet/container runtime, fix node resources, or replace the node.

---

## 11. `Readiness Probe Failed`

**Meaning:** Pod is running but not ready to receive traffic.

**Common causes:**

* App still starting
* Wrong health endpoint
* Dependency unavailable
* Probe timeout too aggressive

**Check:**

```bash
kubectl describe pod <pod>
kubectl logs <pod>
```

**Fix:** Fix health endpoint, increase probe delay/timeout, or resolve app dependency issue.

---

## 12. `Liveness Probe Failed`

**Meaning:** Kubernetes thinks the app is unhealthy and restarts it.

**Common causes:**

* Wrong liveness endpoint
* App temporarily slow
* Probe too strict
* Deadlocked app

**Fix:** Tune probe settings or separate liveness from readiness checks.

Example:

```yaml
initialDelaySeconds: 30
timeoutSeconds: 5
failureThreshold: 3
```

---

## 13. `Back-off Restarting Failed Container`

**Meaning:** Kubernetes is delaying restarts because the container keeps failing.

**Common causes:**

* App crash
* Bad deployment
* Bad config
* Failed dependency

**Check:**

```bash
kubectl logs <pod> --previous
kubectl describe pod <pod>
```

**Fix:** Fix root cause, then restart rollout if needed.

---

## 14. `FailedScheduling`

**Meaning:** Scheduler cannot place the pod on any node.

**Common causes:**

* Insufficient CPU/memory
* Node affinity mismatch
* Taints without tolerations
* PVC zone conflict

**Check:**

```bash
kubectl describe pod <pod>
```

**Fix:** Adjust resource requests, node affinity, tolerations, or storage configuration.

---

## 15. `Unauthorized` / `Forbidden`

**Meaning:** Kubernetes API denies the action.

**Common causes:**

* Missing RBAC permissions
* Wrong service account
* Expired token
* Incorrect kubeconfig context

**Check:**

```bash
kubectl auth can-i get pods
kubectl auth can-i create deployments --as system:serviceaccount:<namespace>:<serviceaccount>
kubectl config current-context
```

**Fix:** Update Role/ClusterRole and RoleBinding/ClusterRoleBinding, or switch to the correct context/service account.

---

## Most important ones to master for interviews

Focus especially on:

* `CrashLoopBackOff`
* `ImagePullBackOff`
* `Pending`
* `OOMKilled`
* `Evicted`
* `NodeNotReady`
* `Readiness Probe Failed`
* `FailedScheduling`
* `Forbidden`

These are the ones most likely to appear in real SRE troubleshooting questions.
