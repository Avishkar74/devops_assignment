<video controls src="videos/20261007-1615-13.6160353.mp4" title="Title"></video>

# Task 2: Troubleshoot Common Issues

Each entry is issue > investigation > root cause > fix. This task has no screenshots, only the recording above, so the before/after outputs are not written out here.

---

## 1. CrashLoopBackOff
- **Issue:** the pod `crash-demo` (`06-crashloopbackoff/broken-pod.yaml`) keeps restarting.
- **Investigation:** `kubectl logs crash-demo`, `kubectl logs --previous` and `kubectl describe pod crash-demo`.
- **Root cause:** the container command runs `exit 1`, so it exits right after starting.
- **Fix:** replaced it with `fixed-pod.yaml`, where the command runs `sleep 3600` instead of crashing.

---

## 2. ImagePullBackOff / ErrImagePull
- **Issue:** the pod `image-demo` (`07-imagepullbackoff/broken-pod.yaml`) cannot start.
- **Investigation:** `kubectl describe pod image-demo` and read the Events for the pull error.
- **Root cause:** the image tag `nginx:this-image-does-not-exist` does not exist in the registry.
- **Fix:** replaced it with `fixed-pod.yaml` using the valid tag `nginx:1.27`.

---

## 3. Pending Pod
- **Issue:** the pod `pending-demo` (`08-pending-pods/broken-pod.yaml`) stays Pending.
- **Investigation:** `kubectl describe pod pending-demo`, and the Events showed `FailedScheduling`.
- **Root cause:** `nodeSelector` pointed to `node-that-does-not-exist`, so no node matched.
- **Fix:** replaced it with `fixed-pod.yaml` with the `nodeSelector` removed.

---

## 4. Service Connectivity Issue
- **Issue:** `web-service` (`09-service-dns-troubleshooting/service.yaml`) did not reach the pods.
- **Investigation:** `kubectl get endpoints web-service` (empty) and `kubectl get pods --show-labels`.
- **Root cause:** the service selector `app=web-ahsgdf` did not match the pod label `app=web`, so Endpoints were empty.
- **Fix:** `kubectl patch svc web-service -p '{"spec":{"selector":{"app":"web"}}}'`

---

## 5. DNS Issue
- **Issue:** I could not test DNS because the `dns-test` pod did not start.
- **Investigation:** the `dnsutils` image gave `ImagePullBackOff`. I then used `kubectl exec dns-test -- nslookup web-service` and `kubectl logs -n kube-system -l k8s-app=kube-dns` to check DNS.
- **Root cause:** the test image `dnsutils` could not be pulled.
- **Fix:** `kubectl run dns-test --image=busybox:1.36 --restart=Never -- sleep 3600`
