# Kubernetes Commands untuk Setiap Resource

## 0. Setup dari Awal (Build & Deploy)

### Prasyarat

```bash
# Pastikan sudah terinstall:
# - Docker/Podman
# - Minikube
# - Kubectl
# - Helm

# Cek versi
docker --version
# atau
podman --version

minikube version
kubectl version --client
helm version
```

### Step 1: Build Docker Image

```bash
# Pastikan ada file Dockerfile dan requirements.txt
# Build image dengan podman atau docker

# Opsi A: Build dengan Podman (jika pakai Podman)
podman build -t my-registry/python-api:v1.0.0 .

# Opsi B: Build dengan Docker
docker build -t my-registry/python-api:v1.0.0 .
```

### Step 2: Start Minikube

```bash
# Start minikube cluster
minikube start

# Atau dengan driver podman
minikube start --driver=podman

# Atau dengan driver docker
minikube start --driver=docker

# Cek status
minikube status
```

### Step 3: Load Image ke Minikube

```bash
# Opsi A: Build langsung di minikube (RECOMMENDED)
minikube image build -t my-registry/python-api:v1.0.0 .

# Opsi B: Load dari local (jika sudah build di local)
# Dengan Docker
minikube image load my-registry/python-api:v1.0.0

# Dengan Podman - save dulu ke tar, lalu load
podman save -o python-api.tar my-registry/python-api:v1.0.0
minikube image load python-api.tar

# Verify image sudah ada di minikube
minikube image ls | grep python-api
```

### Step 4: Deploy dengan Helm

```bash
# Pastikan sudah di root project directory
cd /path/to/learn_fastapi

# Install/Deploy aplikasi dengan default values
helm install python-api ./k8s

# Atau override values dengan custom file
helm install python-api ./k8s -f values-custom.yaml

# Atau override specific values
helm install python-api ./k8s --set replicaCount=3 --set image.tag=v1.0.1

# Combine: default + custom + override
helm install python-api ./k8s -f values-prod.yaml --set replicaCount=5

# Cek status deployment
kubectl get all

# Tunggu pods running
kubectl get pods -w
```

### Step 5: Akses Aplikasi

```bash
# Get service URL
minikube service python-api --url

# Atau buka di browser
minikube service python-api

# Test endpoint
curl http://127.0.0.1:<PORT>/
curl http://127.0.0.1:<PORT>/health
```

### Update Aplikasi (Rebuild & Redeploy)

```bash
# 1. Edit kode aplikasi (main.py, dll)

# 2. Rebuild image di minikube (increment version)
minikube image build -t my-registry/python-api:v1.0.1 .

# 3. Update values.yaml atau edit langsung
# Edit k8s/values.yaml, ubah tag: v1.0.1

# 4. Upgrade deployment
helm upgrade python-api ./k8s

# 5. Atau restart deployment tanpa upgrade
kubectl rollout restart deployment python-api

# 6. Monitor rollout
kubectl rollout status deployment python-api
```

### Troubleshooting Setup

```bash
# Jika pods error, cek logs
kubectl logs -l app=python-api --tail=50

# Cek events
kubectl get events --sort-by='.lastTimestamp'

# Cek pod details
kubectl describe pod <pod-name>

# Cek image ada di minikube
minikube ssh
docker images | grep python-api
exit

# Restart minikube jika ada masalah
minikube stop
minikube start
```

---

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
# Deploy dengan default values
helm install python-api ./k8s

# Deploy dengan custom values file
helm install python-api ./k8s -f values-prod.yaml

# Deploy dengan multiple values files (merge dari kiri ke kanan)
helm install python-api ./k8s -f values-base.yaml -f values-prod.yaml

# Deploy dengan override inline
helm install python-api ./k8s --set replicaCount=5 --set image.tag=v2.0.0

# Combine all: base + custom file + inline override
helm install python-api ./k8s \
  -f values-prod.yaml \
  --set service.type=LoadBalancer \
  --set image.tag=v2.0.0

# Dry-run (preview tanpa deploy)
helm install python-api ./k8s --dry-run --debug

# Upgrade deployment (update dengan values baru)
helm upgrade python-api ./k8s

# Upgrade dengan custom values
helm upgrade python-api ./k8s -f values-prod.yaml --set replicaCount=10

# Upgrade atau install (jika belum ada)
helm upgrade --install python-api ./k8s -f values-prod.yaml

# Uninstall
helm uninstall python-api

# List semua releases
helm list

# Lihat history release
helm history python-api

# Rollback ke revision sebelumnya
helm rollback python-api

# Rollback ke revision tertentu
helm rollback python-api 2

# Via kubectl langsung (tidak pakai Helm)
kubectl apply -f k8s/templates/
```

### Contoh Values Files untuk Environment Berbeda

```bash
# values-dev.yaml
cat > values-dev.yaml <<EOF
replicaCount: 1
image:
  tag: latest
  pullPolicy: Always
service:
  type: NodePort
resources:
  requests:
    cpu: 50m
    memory: 64Mi
env:
  APP_ENV: development
EOF

# values-staging.yaml
cat > values-staging.yaml <<EOF
replicaCount: 2
image:
  tag: v1.0.0-rc1
service:
  type: ClusterIP
ingress:
  enabled: true
  host: api.staging.example.com
env:
  APP_ENV: staging
EOF

# values-prod.yaml
cat > values-prod.yaml <<EOF
replicaCount: 10
image:
  tag: v1.0.0
  pullPolicy: IfNotPresent
service:
  type: LoadBalancer
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 2Gi
hpa:
  enabled: true
  minReplicas: 10
  maxReplicas: 50
  cpuUtilization: 70
env:
  APP_ENV: production
EOF

# Deploy ke environment berbeda
helm install python-api-dev ./k8s -f values-dev.yaml
helm install python-api-staging ./k8s -f values-staging.yaml
helm install python-api-prod ./k8s -f values-prod.yaml
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
