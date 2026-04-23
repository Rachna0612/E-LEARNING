#!/bin/bash
# Install Prometheus and Grafana monitoring stack
# Run this on Master Node

set -e

echo "=========================================="
echo "Installing Monitoring Stack"
echo "=========================================="

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Add Prometheus Helm repository
echo "[1/4] Adding Prometheus Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
echo "[2/4] Creating monitoring namespace..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install Prometheus stack
echo "[3/4] Installing Prometheus + Grafana stack..."
echo "This may take 3-5 minutes..."
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.service.type=NodePort \
  --set prometheus.service.nodePort=30090 \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=30030 \
  --set grafana.adminPassword=admin123

# Wait for pods
echo "[4/4] Waiting for monitoring pods to be ready..."
echo "This may take 2-3 minutes..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s

echo ""
echo "=========================================="
echo "Monitoring Stack Installed!"
echo "=========================================="
echo ""
echo "Grafana:"
echo "  URL: http://<NODE_IP>:30030"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "Prometheus:"
echo "  URL: http://<NODE_IP>:30090"
echo ""
echo "Get node IPs with: kubectl get nodes -o wide"
echo ""
echo "Check monitoring pods:"
kubectl get pods -n monitoring
echo ""
echo "Recommended Grafana Dashboards:"
echo "  - 15760: Kubernetes cluster monitoring"
echo "  - 15759: Kubernetes pods monitoring"
echo "  - 1860: Node Exporter Full"
echo ""
