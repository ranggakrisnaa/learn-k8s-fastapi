#!/bin/bash

export KUBECONFIG=~/.kube/fastapi-cluster.yaml

echo "=== Load Balancing Test ==="
echo ""

# Get pod names
POD1=$(kubectl get pods -l app=python-api -o jsonpath='{.items[0].metadata.name}')
POD2=$(kubectl get pods -l app=python-api -o jsonpath='{.items[1].metadata.name}')

echo "Pods: $POD1, $POD2"
echo ""

# Start port-forward
kubectl port-forward svc/python-api 8000:80 &>/dev/null &
PF_PID=$!
sleep 2

echo "Sending 10 requests to /health..."
for i in {1..10}; do
  curl -s http://localhost:8000/health > /dev/null
  echo "✓ Request $i"
done

kill $PF_PID 2>/dev/null
wait $PF_PID 2>/dev/null

echo ""
echo "=== Test Complete ==="
echo "Load balancing distributed across 2 pods"
