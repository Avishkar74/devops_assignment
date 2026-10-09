# Configmap

![alt text](images/image.png)

> In `01-configmap`: `kubectl apply -f app-config.yaml`, `get configmap yatri-app-config` (5 keys), `describe` with the five values, `get ... -o jsonpath='{.data.LOG_LEVEL}'` printing INFO, and `kubectl delete configmap`.  
> This shows creating, reading and deleting a ConfigMap.  

# Secrets

![alt text](images/image-1.png)

> In `02-secret`: three `echo -n ... | base64` commands, a failed `kubectl apply -f secret/db-secret.yaml` ("the path ... does not exist"), then `kubectl apply -f db-secret.yaml` creating `yatri-db-secret` (3 items), a decoded password via `jsonpath | base64 --decode`, and `kubectl delete secret`.  
> This shows the secret flow and a wrong-path error.  

# Ingress

![alt text](images/image-2.png)

> In `03-ingress`: `kubectl apply -f ingress-routes.yaml`, `get ingress yatri-ingress` (class nginx, host `yatri.local`), and `describe` showing rules for `/api` and `/` whose backend services are listed as "not found". Then `openssl req -x509` makes `tls.crt`/`tls.key`, `kubectl create secret tls campus-tls-cert`, `ingress-tls.yaml` is applied, and a `curl -k --resolve` is run.  
> This shows ingress routing and TLS setup.  
