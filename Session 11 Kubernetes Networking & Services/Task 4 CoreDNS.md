# Task 4: CoreDNS in Kubernetes

This document provides a comprehensive guide to **CoreDNS** in Kubernetes, explaining its architecture, service discovery mechanism, query resolution flow, configuration structure, and step-by-step troubleshooting techniques.

---

## 1. What is CoreDNS?

**CoreDNS** is a fast, flexible, and extensible DNS server written in Go. It is a **CNCF (Cloud Native Computing Foundation) graduated project** and serves as the default cluster DNS server in Kubernetes (replacing the older `kube-dns` since Kubernetes v1.13).

CoreDNS runs inside the `kube-system` namespace as a deployment (usually 2 replicas) and exposes a ClusterIP service called `kube-dns`.

---

## 2. Why Kubernetes Uses CoreDNS

Kubernetes adopted CoreDNS for several key reasons:

1. **Plugin-Based Architecture:** Everything in CoreDNS is a plugin. Features like Kubernetes service discovery, caching, metrics, and forwarding are modular and can be enabled or disabled easily.
2. **High Performance & Low Memory Footprint:** Written in Go, CoreDNS is lightweight, fast, and handles high request volumes efficiently.
3. **Native Kubernetes API Integration:** CoreDNS connects directly to the Kubernetes API server to watch Services and Endpoints in real-time.
4. **Single Binary Executable:** CoreDNS compiles into a small binary with no runtime dependencies, making container images secure and small.

---

## 3. How Service Discovery Works

Kubernetes service discovery enables Pods to locate other Services dynamically via DNS.

```text
[ Kubernetes API Server ]
       | (Watch Event: Service Created/Deleted)
       v
  [ CoreDNS ]  <--- (Updates In-Memory DNS Records)
       ^
       | (DNS Query for "order-service")
  [ Client Pod ]
```

1. **API Watching:** CoreDNS uses its `kubernetes` plugin to maintain an active watch on the Kubernetes API Server for `Service` and `Endpoints` resources.
2. **Dynamic In-Memory Updates:** Whenever a Service is created, modified, or deleted, CoreDNS immediately updates its internal DNS lookup table in memory without requiring a restart.
3. **Service Lookup:** When a Pod queries `order-service`, CoreDNS resolves it to the Service's virtual `ClusterIP`.

---

## 4. How DNS Queries are Resolved

CoreDNS processes queries differently based on whether the requested domain is **internal** to the cluster or **external**.

### A. Internal Cluster Queries (`*.cluster.local`)

```text
Pod (curl http://auth-svc)
  │
  ├─► Checks /etc/resolv.conf (appends "default.svc.cluster.local")
  │
  ├─► Sends UDP Query to CoreDNS IP (10.96.0.10)
  │
  ├─► CoreDNS 'kubernetes' plugin matches "auth-svc.default.svc.cluster.local"
  │
  └─► Returns ClusterIP (e.g. 10.100.45.12)
```

### B. External Queries (e.g. `google.com` or `api.github.com`)

```text
Pod (curl https://api.github.com)
  │
  ├─► Sends DNS Query to CoreDNS IP (10.96.0.10)
  │
  ├─► CoreDNS 'kubernetes' plugin checks domain -> NOT cluster.local
  │
  ├─► CoreDNS passes query to 'forward' plugin
  │
  ├─► CoreDNS forwards query to Upstream DNS (Host Node DNS / 8.8.8.8)
  │
  └─► Returns Public IP back to Pod
```

---

## 5. CoreDNS Configuration (`Corefile`)

CoreDNS is configured via a ConfigMap named `coredns` in the `kube-system` namespace. The main configuration block is called the **Corefile**.

### Inspecting the ConfigMap
```bash
kubectl get configmap coredns -n kube-system -o yaml
```

### Example Corefile & Plugin Breakdown

```txt
.:53 {
    errors
    health {
       lameduck 5s
    }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       fallthrough in-addr.arpa ip6.arpa
       ttl 30
    }
    prometheus :9153
    forward . /etc/resolv.conf {
       max_concurrent 1000
    }
    cache 30
    loop
    reload
    loadbalance
}
```

#### Plugin Explanations:

| Plugin | Function |
| :--- | :--- |
| `errors` | Logs errors to stdout for debugging. |
| `health` | Provides an HTTP health check endpoint on port 8080 (`/health`). |
| `ready` | Signals readiness to Kubernetes probes on port 8181 (`/ready`). |
| `kubernetes` | Resolves DNS queries for Kubernetes Services and Pods within `cluster.local`. |
| `prometheus` | Exposes Prometheus metrics on port 9153 (`/metrics`). |
| `forward` | Forwards non-cluster DNS queries to external DNS servers (e.g., node `/etc/resolv.conf`). |
| `cache` | Caches DNS responses in memory for 30 seconds to reduce lookup latency. |
| `loop` | Detects simple DNS forwarding loops and halts CoreDNS to prevent crashes. |
| `reload` | Automatically reloads CoreDNS when the `Corefile` ConfigMap is updated. |
| `loadbalance` | Randomizes the order of A/AAAA records to balance traffic across replicas. |

---

## 6. How to Troubleshoot DNS Issues

When Pods cannot resolve service names or external domains, follow this step-by-step diagnostic workflow:

### Step 1: Check if CoreDNS Pods are Running
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```
*Expected Output:* `STATUS` should be `Running` and `READY` should be `1/1`.

### Step 2: Verify `kube-dns` Service and Endpoints
```bash
# Verify Service IP exists
kubectl get svc -n kube-system -l k8s-app=kube-dns

# Verify CoreDNS pods are attached to the endpoint
kubectl get endpoints -n kube-system -l k8s-app=kube-dns
```
*If Endpoints are empty `<none>`, CoreDNS pods are failing health probes or labels do not match.*

### Step 3: Check CoreDNS Logs
```bash
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50
```
*Look for errors like upstream timeouts, permission issues, or syntax errors in Corefile.*

### Step 4: Verify Pod `/etc/resolv.conf`
Exec into the failing application Pod and inspect its DNS resolver configuration:
```bash
kubectl exec -it <pod-name> -- cat /etc/resolv.conf
```
*Ensure `nameserver` matches the `kube-dns` Service IP (e.g. `10.96.0.10`).*

### Step 5: Run a DNS Testing Pod (`dnsutils`)
Launch a temporary pod with DNS diagnostic tools (`nslookup`, `dig`):

```bash
kubectl run dns-test --rm -i --tty --image=infoblox/dnstools -- restart=Never -- sh
```

Inside the test pod, run:
```bash
# Test internal cluster DNS resolution
nslookup kubernetes.default

# Test specific Service FQDN
nslookup my-service.default.svc.cluster.local

# Test external DNS resolution
dig google.com
```

### Common DNS Issues & Solutions

1. **Issue:** `NXDOMAIN` for valid Services.
   - **Fix:** Check if the Service exists in the correct namespace and label selectors match.
2. **Issue:** External lookup (`google.com`) fails, but internal works.
   - **Fix:** Check the `forward` plugin in Corefile and verify the host node has internet access.
3. **Issue:** High DNS lookup latency (>5s).
   - **Fix:** Check for `ndots:5` search domain overhead or enable NodeLocal DNSCache.
