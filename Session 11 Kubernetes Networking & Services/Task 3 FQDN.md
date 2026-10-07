# Task 3: Kubernetes FQDN (Fully Qualified Domain Name)

This document explains Fully Qualified Domain Names (FQDN) in Kubernetes, covering DNS structure, naming conventions, namespace resolution, and communication patterns.

---

## 1. What is FQDN?

A **Fully Qualified Domain Name (FQDN)** is the complete, absolute domain name for a specific host or service on a network. It specifies all domain levels, including the hostname and the top-level domain.

- **Partial Hostname (Relative):** `backend`
- **Fully Qualified Domain Name (Absolute):** `backend.production.svc.cluster.local.`

In Kubernetes, FQDNs provide a stable, human-readable way for microservices to discover and communicate with each other regardless of changing Pod IP addresses.

---

## 2. Kubernetes Service DNS

Kubernetes runs an internal cluster DNS server (typically **CoreDNS**) that monitors the Kubernetes API for new, modified, or deleted Services.

- Whenever a **Service** is created, CoreDNS automatically generates a corresponding DNS record for it.
- Pods inside the cluster automatically use CoreDNS to translate Service names into ClusterIP addresses.
- This eliminates the need to hardcode IP addresses in application configurations.

---

## 3. Kubernetes DNS Naming Convention

### Service FQDN Format

The standard FQDN format for a Kubernetes Service is:

```text
<service-name>.<namespace>.svc.<cluster-domain>
```

#### Component Breakdown:

| Component | Description | Example |
| :--- | :--- | :--- |
| `<service-name>` | The name given to the Kubernetes Service object. | `order-service` |
| `<namespace>` | The namespace where the Service resides. | `payments` |
| `svc` | Identifies that this DNS record belongs to a Service. | `svc` |
| `<cluster-domain>` | The base domain name of the Kubernetes cluster (default is `cluster.local`). | `cluster.local` |

---

## 4. Namespace-based DNS & Short Names

Pods can access Services using different levels of domain specificity based on namespaces.

### 1. Same Namespace Communication (Short Name)
If a Pod and a Service are in the **same namespace**, the Pod can reach the Service using just its short name.

- **Example:** `curl http://payment-service`

### 2. Cross-Namespace Communication
If a Pod in namespace `frontend` needs to talk to a Service in namespace `backend`, it must include the namespace name.

- **Namespace Relative:** `payment-service.backend`
- **Full FQDN:** `payment-service.backend.svc.cluster.local`

### How Short Names Work (`/etc/resolv.conf`)
Every Kubernetes Pod automatically receives a `/etc/resolv.conf` file containing search paths:

```text
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

When a Pod queries `payment-service`, DNS automatically appends search domains until a match is found.

---

## 5. Pod-to-Service Communication Flow

```text
[ Pod A ] --(1) Request "http://user-service"--> [ CoreDNS ]
                                                        |
[ Pod A ] <-- (2) Returns ClusterIP (10.96.15.42) ------+
    |
    +--(3) Sends TCP traffic to 10.96.15.42 --> [ kube-proxy / Service ]
                                                        |
                                            (4) Load Balances
                                                        |
                                                v       v
                                           [ Pod B ] [ Pod C ]
```

1. **DNS Query:** Pod A sends a DNS lookup for `user-service` to CoreDNS (`10.96.0.10`).
2. **DNS Response:** CoreDNS resolves `user-service.default.svc.cluster.local` to its virtual ClusterIP (`10.96.15.42`).
3. **Traffic Transmission:** Pod A sends HTTP network packets to `10.96.15.42`.
4. **Service Load Balancing:** `kube-proxy` / CNI intercepts traffic to the ClusterIP and forwards it to one of the backing healthy Pods (`Pod B` or `Pod C`).

---

## 6. Examples of Kubernetes FQDNs

| Scenario | Kubernetes Object | Example FQDN |
| :--- | :--- | :--- |
| **Standard Service** in `default` namespace | ClusterIP Service | `web-service.default.svc.cluster.local` |
| **Cross-Namespace Service** in `finance` namespace | ClusterIP Service | `billing-api.finance.svc.cluster.local` |
| **StatefulSet Pod** (Headless Service) | Pod `db-0` under Headless Service `mysql` in `database` namespace | `db-0.mysql.database.svc.cluster.local` |
| **Direct Pod IP DNS** | Pod IP `10.244.1.5` in `default` namespace | `10-244-1-5.default.pod.cluster.local` |
| **External Service** | ExternalName Service pointing to `api.stripe.com` | `stripe-service.default.svc.cluster.local` $\rightarrow$ `api.stripe.com` |
