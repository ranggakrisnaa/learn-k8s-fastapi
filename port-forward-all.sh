#!/bin/bash

export KUBECONFIG=~/.kube/fastapi-cluster.yaml

echo "================================================"
echo "Port Forward Setup - Prometheus & Grafana"
echo "================================================"

# Check cluster connection
if ! kubectl cluster-info &>/dev/null; then
  echo "✗ Unable to connect to cluster"
  exit 1
fi

echo "✓ Cluster connected"

# Port-forward Prometheus
echo ""
echo "Starting Prometheus port-forward..."
echo "  → localhost:9090 (Prometheus)"
kubectl port-forward -n prometheus svc/prometheus-kube-prometheus-prometheus 9090:9090 &
PROM_PID=$!

# Port-forward Grafana
echo "Starting Grafana port-forward..."
echo "  → localhost:3000 (Grafana)"
kubectl port-forward -n default svc/grafana 3000:3000 &
GRAFANA_PID=$!

# Port-forward FastAPI
echo "Starting FastAPI port-forward..."
echo "  → localhost:8000 (FastAPI API)"
echo "  → localhost:8000/metrics (Prometheus metrics)"
kubectl port-forward -n default svc/python-api 8000:80 &
API_PID=$!

echo ""
echo "================================================"
echo "All services forwarded. Press Ctrl+C to stop."
echo "================================================"
echo ""
echo "Access URLs:"
echo "  • FastAPI API: http://localhost:8000"
echo "  • FastAPI Metrics: http://localhost:8000/metrics"
echo "  • Prometheus: http://localhost:9090"
echo "  • Grafana: http://localhost:3000 (admin/admin)"
echo ""

# Wait for all processes
wait
