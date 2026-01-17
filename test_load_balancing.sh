#!/bin/bash

echo "=== Testing Load Balancing ==="
echo ""

# 1. Get NodePort dynamically
echo "Getting service NodePort..."
NODEPORT=$(kubectl get service python-api -o jsonpath='{.spec.ports[0].nodePort}')
SERVICE_URL="http://127.0.0.1:$NODEPORT"
echo "Service URL: $SERVICE_URL"
echo ""

# 2. Test load balancing (kirim 10 requests)
echo "Sending 10 requests..."
for i in {1..10}; do
  echo -n "Request $i: "
  curl -s $SERVICE_URL/
done

echo ""
echo "=== Checking Pod Logs ==="
echo ""

# 3. Get pod names dynamically
POD1=$(kubectl get pods -l app=python-api -o jsonpath='{.items[0].metadata.name}')
POD2=$(kubectl get pods -l app=python-api -o jsonpath='{.items[1].metadata.name}')

echo "Pod 1: $POD1"
kubectl logs $POD1 --tail=10
echo ""

echo "Pod 2: $POD2"
kubectl logs $POD2 --tail=10
echo ""

echo "=== Load balancing test complete! ==="