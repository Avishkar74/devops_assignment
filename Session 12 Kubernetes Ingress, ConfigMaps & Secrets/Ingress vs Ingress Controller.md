# Task 4: Ingress vs Ingress Controller

---

## 1. What is Ingress?

An **Ingress** is a Kubernetes API object (`kind: Ingress`) that defines the **rules** for routing external HTTP/HTTPS traffic into services running inside a Kubernetes cluster. 

* It is a **declarative manifest file** written in YAML.
* It defines host-based routing (e.g., `api.example.com` vs `web.example.com`), path-based routing (e.g., `/api` vs `/static`), and SSL/TLS termination.
* **Analogy:** Think of Ingress as a **traffic rulebook or a blueprint**. It describes *where* incoming traffic should go, but it cannot process or route network packets on its own.

---

## 2. What is an Ingress Controller?

An **Ingress Controller** is the actual **application or pod** (a reverse proxy) running inside the Kubernetes cluster that evaluates and executes the rules defined in `Ingress` objects.

* Popular Ingress Controllers include **NGINX Ingress Controller**, **Traefik**, **HAProxy**, **Envoy (Contour/Emissary)**, and **AWS ALB Ingress Controller**.
* It constantly watches the Kubernetes API server for new or updated `Ingress` resources and automatically updates its reverse proxy configuration in real time.
* **Analogy:** Think of an Ingress Controller as the **traffic police officer or security guard**. It stands at the entrance of your cluster, reads the rulebook (Ingress), and actively directs incoming web traffic to the correct Pods and Services.

---

## 3. Key Differences Between Ingress and Ingress Controller

| Feature | Ingress (`kind: Ingress`) | Ingress Controller |
| :--- | :--- | :--- |
| **What is it?** | A Kubernetes API Resource / Manifest file | An active application / Daemon / Pod (Reverse Proxy) |
| **Role** | Defines routing rules and configuration | Executes routing rules and handles live network traffic |
| **Analogy** | The Blueprint / Rulebook | The Construction Worker / Traffic Guard |
| **Built-in to K8s?** | Yes (Kubernetes API definition) | No (Must be installed separately, e.g. NGINX) |
| **Execution** | Passive data stored in `etcd` | Active process running in a pod listening on port 80/443 |
| **Examples** | `ingress.yaml` file | `ingress-nginx`, `Traefik`, `HAProxy`, `AWS ALB Controller` |

---

## 4. Why Both Are Required

Both components are required for external traffic routing to work in Kubernetes:

1. **Ingress without an Ingress Controller:**
   If you create an `Ingress` YAML resource in a cluster where no Ingress Controller is installed, the resource will simply sit in `etcd` with an empty `ADDRESS` field. No ports will be opened, and no traffic will be routed.
   
2. **Ingress Controller without an Ingress Resource:**
   If you install an `Ingress Controller` (like NGINX), the proxy container is running and listening on ports 80/443, but it has no routing rules configured. It will simply return `404 Not Found` for all incoming requests until an `Ingress` rule is applied.

> **Summary:** The **Ingress** provides the *configuration*, while the **Ingress Controller** provides the *implementation*.

---

## 5. Practical Examples

### Example A: Ingress Resource Manifest (`ingress.yaml`)

This YAML manifest defines the routing rules:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: yatri-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx   # Specifies which Ingress Controller handles this rule
  rules:
    - host: yatri.local
      http:
        paths:
          # Route /api/* to backend service
          - path: /api(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: yatri-backend-service
                port:
                  number: 80
          # Route / to frontend service
          - path: /
            pathType: Prefix
            backend:
              service:
                name: yatri-frontend-service
                port:
                  number: 80
```

### Example B: Ingress Controller Installation

To make the above `Ingress` manifest work, you must install an Ingress Controller in your cluster:

```bash
# On Minikube:
minikube addons enable ingress

# On Production / Cloud Clusters (via Helm):
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx
```

---

## Summary Diagram

```text
Incoming Web Request (http://yatri.local/api/)
                   |
                   v
   +-------------------------------+
   |   Ingress Controller (Pod)    |  <--- Reads rules from Ingress Object
   |   (e.g., NGINX / Traefik)     |
   +-------------------------------+
                   |
        Path-based Routing (/api)
                   |
                   v
    +-----------------------------+
    |   yatri-backend-service     |  (ClusterIP)
    +-----------------------------+
                   |
                   v
           +---------------+
           |  Backend Pod  |
           +---------------+
```
