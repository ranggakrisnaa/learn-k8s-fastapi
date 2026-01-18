#!/bin/bash

# K3D Cluster Setup Script
# Creates k3d cluster with nodes matching replica count

set -e

# Configuration
CLUSTER_NAME="fastapi-cluster"
REPLICA_COUNT=2
AGENTS=$((REPLICA_COUNT + 1))  # 1 server + agents for replicas
SERVER_NODES=1
TOTAL_NODES=$((SERVER_NODES + AGENTS))

echo "================================================"
echo "K3D Cluster Setup"
echo "================================================"
echo "Cluster Name: $CLUSTER_NAME"
echo "Replica Count: $REPLICA_COUNT"
echo "Server Nodes: $SERVER_NODES"
echo "Agent Nodes: $AGENTS"
echo "Total Nodes: $TOTAL_NODES"
echo "================================================"

# Check if Docker is running
echo "Checking Docker daemon..."
if ! docker ps &> /dev/null; then
    echo "ERROR: Docker daemon is not running!"
    echo ""
    echo "Please start Docker/OrbStack first:"
    echo "  - macOS: Open OrbStack or Docker Desktop from Applications"
    echo ""
    echo "Then run this script again."
    exit 1
fi
echo "✓ Docker daemon is running"
echo ""

# Check if cluster already exists
if k3d cluster list | grep -q "^$CLUSTER_NAME$"; then
    echo "Cluster '$CLUSTER_NAME' already exists."
    read -p "Do you want to delete and recreate it? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting existing cluster..."
        k3d cluster delete $CLUSTER_NAME
    else
        echo "Using existing cluster."
        exit 0
    fi
fi

# Create k3d cluster with specified number of nodes
echo "Creating k3d cluster with $TOTAL_NODES nodes..."
k3d cluster create $CLUSTER_NAME \
    --servers $SERVER_NODES \
    --agents $AGENTS \
    -p "8080:80@loadbalancer" \
    -p "8443:443@loadbalancer" \
    --registry-create "k3d-registry:5000" \
    --wait \
    --timeout 60s

# Get kubeconfig
echo "Setting up kubeconfig..."
k3d kubeconfig get $CLUSTER_NAME > ~/.kube/$CLUSTER_NAME.yaml
export KUBECONFIG=~/.kube/$CLUSTER_NAME.yaml

# Verify cluster
echo "Verifying cluster setup..."
kubectl cluster-info
echo ""
echo "Nodes:"
kubectl get nodes -o wide

echo ""
echo "================================================"
echo "Cluster Setup Complete!"
echo "================================================"
echo "To use this cluster, run:"
echo "  export KUBECONFIG=~/.kube/$CLUSTER_NAME.yaml"
echo ""
echo "To deploy the application, run:"
echo "  helm install learn-k8s-fastapi ./k8s"
echo "================================================"
