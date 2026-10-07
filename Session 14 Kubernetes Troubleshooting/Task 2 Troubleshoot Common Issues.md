<video controls src="20261007-1615-13.6160353.mp4" title="Title"></video>

# Task 2: Troubleshoot Common Issues

---

## 1. CrashLoopBackOff
- **File:** `06-crashloopbackoff/broken-pod.yaml`
- **Cause:** Container command exits with `exit 1` immediately.
- **Fix:** Replaced with `fixed-pod.yaml` — command runs `sleep 3600` instead of crashing.
- **Commands:** `kubectl logs crash-demo`, `kubectl logs --previous`, `kubectl describe pod crash-demo`

---

## 2. ImagePullBackOff / ErrImagePull
- **File:** `07-imagepullbackoff/broken-pod.yaml`
- **Cause:** Image tag `nginx:this-image-does-not-exist` doesn't exist in registry.
- **Fix:** Replaced with `fixed-pod.yaml` using valid tag `nginx:1.27`.
- **Commands:** `kubectl describe pod image-demo` → checked Events for pull error.

---

## 3. Pending Pod
- **File:** `08-pending-pods/broken-pod.yaml`
- **Cause:** `nodeSelector` pointed to `node-that-does-not-exist` — no node matched.
- **Fix:** Replaced with `fixed-pod.yaml` with `nodeSelector` removed.
- **Commands:** `kubectl describe pod pending-demo` → Events showed `FailedScheduling`.

---

## 4. Service Connectivity Issue
- **File:** `09-service-dns-troubleshooting/service.yaml`
- **Cause:** Service selector `app=web-ahsgdf` didn't match pod label `app=web` → empty Endpoints.
- **Fix:** `kubectl patch svc web-service -p '{"spec":{"selector":{"app":"web"}}}'`
- **Commands:** `kubectl get endpoints web-service`, `kubectl get pods --show-labels`

---

## 5. DNS Issue
- **Cause:** `dns-test` pod using `dnsutils` image had `ImagePullBackOff`. Switched to `busybox:1.36`.
- **Fix:** `kubectl run dns-test --image=busybox:1.36 --restart=Never -- sleep 3600`
- **Commands:** `kubectl exec dns-test -- nslookup web-service`, `kubectl logs -n kube-system -l k8s-app=kube-dns`