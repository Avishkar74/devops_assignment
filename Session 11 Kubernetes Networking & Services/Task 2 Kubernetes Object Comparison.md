# Task 2: Kubernetes Object Comparison

This document provides a clear, simple comparison of key Kubernetes workload objects and networking concepts.

---

## 1. Deployment vs ReplicaSet

### Comparison Summary

| Feature | ReplicaSet | Deployment |
| :--- | :--- | :--- |
| **Purpose** | Guarantees a specified number of Pod replicas are running at all times. | Manages ReplicaSets and provides declarative updates for Pods. |
| **Pod Management** | Directly manages Pods using label selectors. | Indirectly manages Pods by creating and updating ReplicaSets. |
| **Scaling** | Can scale Pods up/down by changing `replicas`. | Scales Pods up/down by updating the underlying ReplicaSet. |
| **Rolling Updates** | **No native support.** Updating pod templates requires manual pod deletion. | **Full native support.** Automatically manages rolling updates and rollbacks. |

### Key Details & Relationship

- **Purpose & Pod Management:** A **ReplicaSet** focuses purely on maintaining pod availability and target count. If a Pod crashes or dies, ReplicaSet spins up a new one. A **Deployment** is a higher-level object built *on top* of ReplicaSets to manage application lifecycles.
- **Rolling Updates & Rollbacks:** If you update an application image in a **Deployment**, it creates a *new* ReplicaSet with the new image, gradually scales up the new ReplicaSet while scaling down the old one (rolling update with zero downtime), and keeps history for easy rollbacks (`kubectl rollout undo`).
- **Relationship:**
  ```text
  Deployment  --->  ReplicaSet  --->  Pods
  ```
  You almost always create and interact with **Deployments** rather than managing ReplicaSets directly.

---

## 2. Deployment vs DaemonSet vs StatefulSet

### Summary Comparison Table

| Feature | Deployment | DaemonSet | StatefulSet |
| :--- | :--- | :--- | :--- |
| **Primary Use Case** | Stateless web apps, APIs, microservices. | Cluster background agents, logging, monitoring. | Databases, message queues, stateful systems. |
| **Pod Creation & Naming** | Random hash names (e.g., `web-75675-abc12`); created in parallel. | One Pod created on **every node** (or target nodes). | Unique sequential names (e.g., `db-0`, `db-1`); created in order. |
| **Scaling** | Scaled via `replicas` field. | Scales automatically as worker nodes join/leave. | Scaled sequentially (0 to N-1). |
| **Networking** | Shared IP pool behind a standard Service. | Node IP / HostPort or Pod network. | Stable, unique DNS records via **Headless Service**. |
| **Storage** | Ephemeral or shared volumes (ReadWriteMany). | Host node paths (`hostPath`). | Dedicated Persistent Volume per Pod via `volumeClaimTemplates`. |
| **Examples** | Nginx, Node.js API, React Frontend. | Fluentd, Prometheus Node Exporter, Calico CNI. | PostgreSQL, MySQL, Redis Cluster, Elasticsearch. |

### Detailed Breakdown

1. **Deployment (Stateless Workloads)**
   - **Use Case:** Applications where all Pod instances are identical and don't care which server or disk they run on.
   - **Networking & Storage:** Requests can hit any pod instance indiscriminately. Pods can share a central volume or use temporary storage.

2. **DaemonSet (Node-level Services)**
   - **Use Case:** Background tasks that must run on every single host node in the Kubernetes cluster.
   - **Scaling:** You do not set a `replicas` count. When you add a new server node to the cluster, DaemonSet automatically deploys a Pod onto it.

3. **StatefulSet (Stateful Workloads)**
   - **Use Case:** Databases and distributed systems that require persistent identity, sticky storage, and ordered startup/shutdown.
   - **Networking & Storage:** Every Pod gets a fixed identity (`db-0`, `db-1`). If `db-0` dies and is recreated on another node, it retains the name `db-0` and reattaches to its *exact same* persistent data disk.

---

## 3. ReplicaSet vs Service

### Responsibilities

- **ReplicaSet Responsibility:** Manages the **lifecycle and quantity** of Pods. It ensures the target number of Pod instances are healthy and running inside the cluster.
- **Service Responsibility:** Manages the **network access and traffic routing**. It provides a single stable IP address, DNS name, and load balances incoming requests across active Pods.

### Why a Service is Required

Pods in Kubernetes are **ephemeral** (temporary). When a Pod crashes, dies, or scales:
1. It is destroyed and replaced by a brand-new Pod.
2. The new Pod gets a **completely new IP address**.

If external clients or other microservices connected directly to Pod IPs, connections would break constantly as Pods get recreated. A **Service** solves this by providing a permanent virtual IP (ClusterIP) and DNS entry that remains constant even while underlying Pods come and go.

### How Traffic Reaches Pods

```text
Client Request  --->  Service (Fixed IP / DNS)
                           |
                     Label Selector (e.g., app=frontend)
                           |
             +-------------+-------------+
             |                           |
        Pod 1 (10.244.1.5)          Pod 2 (10.244.2.8)
```

1. **Client Request:** Traffic is sent to the Service's stable ClusterIP, NodePort, or DNS name.
2. **Label Matching:** The Service constantly tracks Pods matching its `selector` (e.g., `app: web`).
3. **kube-proxy / CNI Routing:** `kube-proxy` routes and load-balances the traffic to one of the healthy Pod IPs currently registered under that selector.
