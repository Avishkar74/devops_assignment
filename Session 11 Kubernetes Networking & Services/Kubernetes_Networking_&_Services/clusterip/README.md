![alt text](images/image.png)

> Applying the ClusterIP deployment (3 pods with IPs 10.244.0.179 to .181) and `service.yaml`; `get svc` shows ClusterIP 10.106.33.236 and `get endpoints` lists the three pod IPs on port 80. A `curl-client` pod runs `curl` on the service and gets the nginx welcome page.  
> This shows a ClusterIP service reaching pods from inside the cluster.  
> **Observation:** The Endpoints list is how the service knows which pods to send traffic to (pods matching its selector). The curl works because it runs inside the cluster, and a ClusterIP has no meaning outside it.

![alt text](images/image-1.png)

> `curl` on 10.96.150.45:8080 is stopped with Ctrl+C (exit code 130), then `curl` on 10.106.33.236:8080 returns the nginx page, and `kubectl port-forward svc/web-service-clusterip 8080:8080` prints "Forwarding from 127.0.0.1:8080 -> 80".  
> This shows a failed and a working request, and port-forward.  
> **Observation:** The first IP does not belong to this service (it is not the one from `get svc`), so the request just hung until I cancelled it. `port-forward` is needed to reach a ClusterIP from my own machine, and it maps 8080 on the service to port 80 of the pod.

![alt text](images/image-2.png)

> Browser at `localhost:8080` showing the "Welcome to nginx!" page.  
> This shows the service answering through the port-forward.  
> **Observation:** This is the same service, reached from outside the cluster only because of the tunnel started by `port-forward`.
