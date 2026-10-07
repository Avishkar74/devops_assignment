<video controls src="20261007-1446-09.4452046.mp4" title="Title"></video>

# Task 1: Kubernetes Volumes & Storage Documentation

---

## 1. Why Do Containers Need Volumes?

By default, container filesystems are **ephemeral**. If a container crashes or is deleted, all data stored inside its local layer is permanently lost. 

A Kubernetes **Volume** provides storage decoupled from individual container lifecycles, enabling data sharing between containers inside a Pod and persistent data retention across Pod restarts.

---

## 2. Ephemeral vs Persistent Storage Types

### A. emptyDir
* **Definition:** An empty directory created automatically when a Pod is assigned to a Node.
* **Lifecycle:** Tied directly to the **Pod**. When the Pod is deleted or evicted, the data inside `emptyDir` is permanently deleted.
* **Sharing:** All containers inside the same Pod can read and write to the same `emptyDir` volume mount.
* **Use Cases:** Scratch space, temporary file caching, intra-pod communication (e.g. web app writing logs and sidecar reading them).

```yaml
volumes:
  - name: scratch-volume
    emptyDir: {}
```

---

### B. hostPath
* **Definition:** Mounts a file or directory from the host worker node's physical filesystem directly into the container.
* **Lifecycle:** Tied to the **worker node** filesystem.
* **Use Cases:** System DaemonSets, node monitoring tools (e.g. `cAdvisor` mounting `/sys`), or logging agents (e.g. `Promtail` mounting `/var/log`).
* **Limitations/Risks:** If a Pod is rescheduled to another node, it loses access to the data stored on the previous node. It also presents security risks by exposing host node paths to containers.

```yaml
volumes:
  - name: node-log-volume
    hostPath:
      path: /var/log
      type: Directory
```

---

### C. PersistentVolume (PV)
* **Definition:** A cluster-level storage resource provisioned statically by a cluster admin or dynamically via a StorageClass.
* **Lifecycle:** Independent of any Pod or Node. Data remains intact even if Pods or Nodes are deleted.
* **Access Modes:**
  * `ReadWriteOnce` (RWO): Mounted as read-write by a **single node**.
  * `ReadOnlyMany` (ROX): Mounted as read-only by **many nodes**.
  * `ReadWriteMany` (RWX): Mounted as read-write by **many nodes**.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: student-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /data/pv-storage
```

---

### D. PersistentVolumeClaim (PVC)
* **Definition:** A user's request for storage. A PVC consumes PV resources in the same way a Pod consumes CPU/Memory resources on a node.
* **Binding:** Kubernetes finds a matching PV that satisfies the PVC request (size, access mode, storage class) and binds them together (`STATUS: Bound`).

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: student-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  storageClassName: manual
```

---

### E. StorageClass
* **Definition:** Defines different profiles or classes of storage (e.g. `fast-ssd`, `standard-hdd`) available in a Kubernetes cluster.
* **Provisioner:** Specifies which volume plugin (CSI driver, e.g. AWS EBS CSI, GCP PD, minikube hostpath) handles creating the physical storage.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: k8s.io/minikube-hostpath
volumeBindingMode: Immediate
```

---

### F. Dynamic Provisioning
* **Definition:** Automatic creation of storage on-demand when a user creates a PVC.
* **Workflow:**
  1. Developer applies a `PersistentVolumeClaim` specifying `storageClassName: standard`.
  2. Kubernetes triggers the provisioner defined in the `StorageClass`.
  3. The StorageClass automatically provisions the underlying physical cloud disk (EBS/PD) and creates a `PersistentVolume` object in Kubernetes.
  4. The PVC automatically binds to the newly provisioned PV without any manual admin intervention.

```text
[ Developer PVC ] ---> [ StorageClass ] ---> [ CSI Provisioner ] ---> [ Auto-created PV & Cloud Disk ]
```

---

## 3. Summary Comparison Table

| Storage Type | Managed By | Lifetime | Storage Location | Primary Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **emptyDir** | Kubernetes | Tied to Pod | Memory / Node Disk | Temporary cache, sidecar logs |
| **hostPath** | Node Host | Tied to Node | Host Node File System | System daemon node logging |
| **PV / PVC** | Admin / CSI | Independent | Cloud Disk / NFS / Local | Databases, stateful apps |
| **StorageClass** | Admin / Provider | Cluster-wide | Storage Controller | Automated dynamic storage |