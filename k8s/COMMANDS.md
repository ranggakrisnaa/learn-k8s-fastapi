# Kubernetes Commands untuk Setiap Resource

## 1. Deployment (deployment.yaml)

**Fungsi:** Mengatur pod aplikasi, replicas, rolling updates, dan resource management

```bash
# Lihat deployment
kubectl get deployment python-api

# Lihat detail deployment
kubectl describe deployment python-api

# Scale deployment manual
kubectl scale deployment python-api --replicas=3

# Edit deployment
kubectl edit deployment python-api

# Lihat rollout history
kubectl rollout history deployment python-api

# Restart deployment (untuk reload config/image baru)
kubectl rollout restart deployment python-api

# Rollback ke versi sebelumnya
kubectl rollout undo deployment python-api

# Lihat pods yang dibuat deployment
kubectl get pods -l app=python-api

# Lihat logs dari semua pods
kubectl logs -l app=python-api --tail=100 -f
```

---

## 2. Service (service.yaml)

**Fungsi:** Expose aplikasi untuk networking internal/eksternal, load balancing antar pods

```bash
# Lihat service
kubectl get service python-api

# Lihat detail service dengan endpoints
kubectl describe service python-api

# Lihat endpoints (pod IPs yang dilayani service)
kubectl get endpoints python-api

# Port forward untuk akses lokal (development)
kubectl port-forward service/python-api 8080:80

# Akses via minikube (untuk NodePort)
minikube service python-api --url

# Test koneksi dari dalam cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://python-api/health
```

---

## 3. Secret (secret.yaml)

**Fungsi:** Menyimpan data sensitif seperti password, token, connection string

```bash
# Lihat list secret
kubectl get secrets

# Lihat detail secret (data ter-encode base64)
kubectl describe secret python-api-secret

# Decode secret value
kubectl get secret python-api-secret -o jsonpath='{.data.DATABASE_URL}' | base64 --decode

# Edit secret
kubectl edit secret python-api-secret

# Create/update secret manual
kubectl create secret generic python-api-secret \
  --from-literal=DATABASE_URL='postgres://user:pass@db' \
  --dry-run=client -o yaml | kubectl apply -f -

# Delete secret
kubectl delete secret python-api-secret
```

---

## 4. Ingress (ingress.yaml)

**Fungsi:** HTTP/HTTPS routing dari luar cluster ke service, domain-based routing

```bash
# Lihat ingress
kubectl get ingress

# Lihat detail ingress dengan rules
kubectl describe ingress python-api-ingress

# Test ingress (tambahkan di /etc/hosts atau C:\Windows\System32\drivers\etc\hosts)
# Tambahkan: <MINIKUBE_IP> api.dev.local
curl http://api.dev.local/

# Get minikube IP
minikube ip

# Enable ingress addon di minikube
minikube addons enable ingress

# Lihat ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

---

## 5. HPA - HorizontalPodAutoscaler (hpa.yaml)

**Fungsi:** Auto-scaling pods berdasarkan CPU/memory usage

```bash
# Lihat HPA status
kubectl get hpa

# Lihat detail HPA dengan metrics
kubectl describe hpa python-api-hpa

# Watch HPA realtime
kubectl get hpa python-api-hpa --watch

# Edit HPA
kubectl edit hpa python-api-hpa

# Generate load untuk test auto-scaling
kubectl run -it --rm load-generator --image=busybox --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://python-api; done"

# Lihat metrics server (required untuk HPA)
kubectl top pods
kubectl top nodes
```

---

## Commands Gabungan

### Deploy semua resources

```bash
# Via Helm (recommended)
helm install python-api ./k8s

# Upgrade deployment
helm upgrade python-api ./k8s

# Uninstall
helm uninstall python-api

# Via kubectl langsung
kubectl apply -f k8s/templates/
```

### Monitoring & Debugging

```bash
# Lihat semua resources
kubectl get all

# Lihat semua resources dengan label
kubectl get all -l app=python-api

# Lihat events (troubleshooting)
kubectl get events --sort-by='.lastTimestamp'

# Exec ke dalam pod
kubectl exec -it <pod-name> -- /bin/bash

# Copy file dari/ke pod
kubectl cp <pod-name>:/app/file.txt ./local-file.txt

# Lihat resource usage
kubectl top pods -l app=python-api
```

### Testing

```bash
# Test health endpoint
curl http://127.0.0.1:<NODEPORT>/health

# Test root endpoint
curl http://127.0.0.1:<NODEPORT>/

# Load test dengan Apache Bench
ab -n 1000 -c 10 http://127.0.0.1:<NODEPORT>/
```

### Cleanup

```bash
# Delete via Helm
helm uninstall python-api

# Delete manual
kubectl delete deployment python-api
kubectl delete service python-api
kubectl delete secret python-api-secret
kubectl delete ingress python-api-ingress
kubectl delete hpa python-api-hpa

# Delete all dengan label
kubectl delete all -l app=python-api
```
