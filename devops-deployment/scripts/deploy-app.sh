#!/bin/bash
# Deploy E-Learning application to Kubernetes
# Run this on Master Node after cluster is ready

set -e

echo "=========================================="
echo "Deploying E-Learning Application"
echo "=========================================="

# Check if kubectl is working
if ! kubectl get nodes &> /dev/null; then
    echo "Error: kubectl is not configured properly"
    exit 1
fi

# Variables (CHANGE THESE)
DOCKER_USERNAME="yourusername"  # Change to your Docker Hub username
IMAGE_NAME="e-learning"
IMAGE_TAG="v1"

echo "Docker Hub Username: $DOCKER_USERNAME"
echo "Image: $DOCKER_USERNAME/$IMAGE_NAME:$IMAGE_TAG"
echo ""

# Clone repository if not exists
if [ ! -d "E-LEARNING" ]; then
    echo "[1/6] Cloning repository..."
    git clone https://github.com/Rachna0612/E-LEARNING.git
else
    echo "[1/6] Repository already exists, skipping clone..."
fi

cd E-LEARNING

# Create Dockerfile
echo "[2/6] Creating Dockerfile..."
cat > Dockerfile << 'EOF'
FROM nginx:alpine
WORKDIR /usr/share/nginx/html
RUN rm -rf ./*
COPY e-learning/ .
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# Build Docker image
echo "[3/6] Building Docker image..."
docker build -t $DOCKER_USERNAME/$IMAGE_NAME:$IMAGE_TAG .

# Push to Docker Hub
echo "[4/6] Pushing to Docker Hub..."
echo "Please login to Docker Hub:"
docker login
docker push $DOCKER_USERNAME/$IMAGE_NAME:$IMAGE_TAG

# Create Kubernetes manifests
echo "[5/6] Creating Kubernetes manifests..."

# Deployment
cat > deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: e-learning-deployment
  labels:
    app: e-learning
spec:
  replicas: 2
  selector:
    matchLabels:
      app: e-learning
  template:
    metadata:
      labels:
        app: e-learning
    spec:
      containers:
      - name: e-learning
        image: $DOCKER_USERNAME/$IMAGE_NAME:$IMAGE_TAG
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
EOF

# Service
cat > service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: e-learning-service
spec:
  type: NodePort
  selector:
    app: e-learning
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080
EOF

# Deploy to Kubernetes
echo "[6/6] Deploying to Kubernetes..."
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

echo ""
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=e-learning --timeout=120s

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
kubectl get deployments
echo ""
kubectl get pods
echo ""
kubectl get services
echo ""
echo "Access your application at:"
echo "http://<NODE_IP>:30080"
echo ""
echo "Get node IPs with: kubectl get nodes -o wide"
echo ""
