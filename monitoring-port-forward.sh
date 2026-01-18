#!/bin/bash

export KUBECONFIG=~/.kube/fastapi-cluster.yaml

echo "================================================"
echo "Monitoring Stack - Port Forward"
echo "================================================"
echo ""

# Get pod names
GRAFANA_POD=$(kubectl -n monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=monitoring" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
PROMETHEUS_POD=$(kubectl -n monitoring get pod -l "prometheus=monitoring" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
ALERTMANAGER_POD=$(kubectl -n monitoring get pod -l "alertmanager=monitoring" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

echo "Grafana Pod: $GRAFANA_POD"
echo "Prometheus Pod: $PROMETHEUS_POD"
echo "AlertManager Pod: $ALERTMANAGER_POD"
echo ""

# Kill existing port-forwards
pkill -f "kubectl.*port-forward" 2>/dev/null

echo "Starting port-forwards..."
echo ""

# Start port-forwards using services instead of pods
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80 &>/dev/null &
kubectl -n monitoring port-forward svc/prometheus-operator-prometheus 9090:9090 &>/dev/null &
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-alertmanager 9093:9093 &>/dev/null &

sleep 2

echo "================================================"
echo "Monitoring Dashboards"
echo "================================================"
echo ""
echo "📊 Grafana:"
echo "   URL: http://localhost:3000"
echo "   User: admin"
echo "   Password: admin123"
echo ""
echo "📈 Prometheus:"
echo "   URL: http://localhost:9090"
echo ""
echo "🔔 AlertManager:"
echo "   URL: http://localhost:9093"
echo ""
echo "Press Ctrl+C to stop port-forwards"
echo "================================================"
echo ""

wait
