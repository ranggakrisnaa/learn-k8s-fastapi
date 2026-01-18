#!/bin/bash

# Port Forward Script for FastAPI Service
export KUBECONFIG=~/.kube/fastapi-cluster.yaml

echo "================================================"
echo "Port Forward Setup"
echo "================================================"
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "ERROR: Cannot connect to cluster"
    echo "Make sure cluster is running: ./setup-k3d.sh"
    exit 1
fi

# Check if service exists
if ! kubectl get svc python-api &> /dev/null; then
    echo "ERROR: Service 'python-api' not found"
    echo "Make sure deployment is running: helm install learn-k8s-fastapi ./k8s"
    exit 1
fi

echo "✓ Cluster connected"
echo "✓ Service found: python-api"
echo ""

# Kill existing port-forward if running
pkill -f "kubectl port-forward svc/python-api" 2>/dev/null

# Start port-forward
echo "Starting port-forward: localhost:8000 → svc/python-api:80"
echo ""
echo "You can now access the API at:"
echo "  http://localhost:8000/"
echo "  http://localhost:8000/health"
echo "  http://localhost:8000/items/?data=test"
echo ""
echo "Press Ctrl+C to stop port-forward"
echo "================================================"
echo ""

kubectl port-forward svc/python-api 8000:80
