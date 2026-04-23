Complete DevOps Deployment Guide
E-Learning Frontend on AWS + Kubernetes + Prometheus + Grafana
Time to Complete: 2 hours
Difficulty: Beginner-friendly
Project: Deploy HTML/CSS/JS frontend with full monitoring

📋 Table of Contents
Architecture Overview
AWS Infrastructure Setup
Docker Setup
Kubernetes Cluster Setup
Application Deployment
Monitoring Setup (Prometheus + Grafana)
Verification & Access
Common Errors & Fixes
Presentation Guide
🏗️ Architecture Overview
What We're Building:
Internet → AWS EC2 (Master Node) → Kubernetes Cluster
                                  ↓
                          [E-Learning Pods]
                                  ↓
                    [Prometheus] → [Grafana]
                          (Monitoring)
Components Explained Simply:
AWS EC2 Instances:

Virtual servers in the cloud where we run everything
Think of them as computers you rent from Amazon
Docker:

Packages your website into a "container" (like a zip file that runs)
Makes deployment consistent everywhere
Kubernetes (K8s):

Manages multiple containers automatically
Restarts crashed apps, scales up/down, distributes traffic
Like a smart manager for your containers
Master Node:

The "brain" of Kubernetes
Makes decisions about where to run containers
Monitors cluster health
Worker Node:

Does the actual work (runs your containers)
Receives instructions from Master
Prometheus:

Collects metrics (CPU, memory, requests)
Stores time-series data
Grafana:

Creates beautiful dashboards from Prometheus data
Visualizes what's happening in your cluster
🚀 AWS Infrastructure Setup
Step 1: EC2 Instances Required
You need 2 instances:

Instance Name	Type	vCPU	RAM	Purpose	Cost/hour
k8s-master	t2.medium	2	4GB	Control Plane	~$0.05
k8s-worker	t2.medium	2	4GB	Run Applications	~$0.05
Why t2.medium?

Kubernetes needs minimum 2GB RAM per node
t2.micro (1GB) will cause crashes
t2.medium is the cheapest option that works
Step 2: Launch EC2 Instances
For BOTH instances, follow these steps:

Go to AWS Console → EC2 → Launch Instance

Name and OS:

Name: k8s-master (then repeat for k8s-worker)
AMI: Ubuntu Server 22.04 LTS (Free tier eligible)
Instance Type:

Select: t2.medium
Key Pair:

Create new key pair: k8s-key.pem
Download and save it securely
On Windows: Move to C:\Users\YourName\.ssh\
Set permissions (Git Bash): chmod 400 k8s-key.pem
Network Settings (CRITICAL):

Click "Edit"
Create Security Group: k8s-security-group
Add these rules:
Step 3: Security Group Rules
Inbound Rules (Allow these ports):

Port Range	Protocol	Source	Purpose
22	TCP	0.0.0.0/0	SSH access (connect to instance)
80	TCP	0.0.0.0/0	HTTP (website access)
443	TCP	0.0.0.0/0	HTTPS (secure website)
6443	TCP	0.0.0.0/0	Kubernetes API Server
2379-2380	TCP	0.0.0.0/0	etcd (K8s database)
10250	TCP	0.0.0.0/0	Kubelet API
10251	TCP	0.0.0.0/0	kube-scheduler
10252	TCP	0.0.0.0/0	kube-controller-manager
30000-32767	TCP	0.0.0.0/0	NodePort Services (apps)
9090	TCP	0.0.0.0/0	Prometheus UI
3000	TCP	0.0.0.0/0	Grafana UI
Port Explanations:

22: SSH - How you connect to the server
80/443: Web traffic - How users access your website
6443: K8s API - Master and Worker communicate here
30000-32767: NodePort range - K8s exposes services here
9090: Prometheus dashboard
3000: Grafana dashboard
Storage:

Keep default: 8GB gp3
(Enough for this project)
Launch Instance

Repeat for second instance
Note Down:

Master Node Public IP: ___.___.___.___
Worker Node Public IP: ___.___.___.___
🐳 Docker Setup
Step 4: Connect to Master Node
Open Git Bash / Terminal:

# Connect to Master Node
ssh -i "k8s-key.pem" ubuntu@<MASTER_PUBLIC_IP>

# Example:
# ssh -i "k8s-key.pem" ubuntu@54.123.45.67
Step 5: Install Docker on Master Node
Run these commands on MASTER NODE:

# Update system
sudo apt-get update

# Install prerequisites
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add user to docker group (no need for sudo)
sudo usermod -aG docker $USER

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verify installation
docker --version
Expected output: Docker version 24.x.x

Step 6: Install Docker on Worker Node
Open NEW terminal, connect to Worker Node:

ssh -i "k8s-key.pem" ubuntu@<WORKER_PUBLIC_IP>
Run the SAME Docker installation commands above on WORKER NODE

☸️ Kubernetes Cluster Setup
Step 7: Install Kubernetes on BOTH Nodes
Run these commands on BOTH Master and Worker:

# Disable swap (K8s requirement)
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Load kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Install kubeadm, kubelet, kubectl
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable kubelet
Step 8: Initialize Kubernetes Cluster (MASTER ONLY)
Run on MASTER NODE only:

# Initialize cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# IMPORTANT: Copy the "kubeadm join" command from output
# It looks like:
# kubeadm join 172.31.x.x:6443 --token abc123... --discovery-token-ca-cert-hash sha256:xyz...
# Save this command - you'll need it for Worker Node!
After initialization completes:

# Configure kubectl for current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verify master is ready
kubectl get nodes
Expected output:

NAME         STATUS     ROLES           AGE   VERSION
k8s-master   NotReady   control-plane   1m    v1.28.x
(NotReady is normal - we need to install network plugin)

Step 9: Install Network Plugin (MASTER ONLY)
Run on MASTER NODE:

# Install Flannel (network plugin)
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Wait 30 seconds, then check
kubectl get nodes
Expected output:

NAME         STATUS   ROLES           AGE   VERSION
k8s-master   Ready    control-plane   2m    v1.28.x
Step 10: Join Worker Node to Cluster
Switch to WORKER NODE terminal:

# Run the kubeadm join command you saved earlier
# Example:
sudo kubeadm join 172.31.x.x:6443 --token abc123.xyz789 --discovery-token-ca-cert-hash sha256:abcdef...
If you lost the join command, generate new one on MASTER:

# On Master Node:
kubeadm token create --print-join-command
Verify cluster on MASTER:

kubectl get nodes
Expected output:

NAME         STATUS   ROLES           AGE   VERSION
k8s-master   Ready    control-plane   5m    v1.28.x
k8s-worker   Ready    <none>          1m    v1.28.x
✅ Kubernetes cluster is ready!

📦 Application Deployment
Step 11: Clone Your Project (MASTER NODE)
# On Master Node:
cd ~
git clone https://github.com/Rachna0612/E-LEARNING.git
cd E-LEARNING/e-learning
Step 12: Create Dockerfile
Run on MASTER NODE:

# Create Dockerfile
cat > Dockerfile << 'EOF'
# Use official Nginx image
FROM nginx:alpine

# Copy website files to Nginx html directory
COPY . /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
EOF
Dockerfile Explanation:

FROM nginx:alpine - Use lightweight Nginx web server
COPY . /usr/share/nginx/html/ - Copy your HTML/CSS/JS files
EXPOSE 80 - Tell Docker the app runs on port 80
CMD - Start Nginx when container starts
Step 13: Build and Push Docker Image
Run on MASTER NODE:

# Login to Docker Hub (create account at hub.docker.com if needed)
docker login
# Enter your Docker Hub username and password

# Build image (replace 'yourusername' with your Docker Hub username)
docker build -t yourusername/e-learning:v1 .

# Push to Docker Hub
docker push yourusername/e-learning:v1

# Verify
docker images
Step 14: Create Kubernetes Deployment YAML
Run on MASTER NODE:

# Create deployment file
cat > deployment.yaml << 'EOF'
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
        image: yourusername/e-learning:v1
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
IMPORTANT: Replace yourusername with your Docker Hub username!

Deployment YAML Explanation:

replicas: 2 - Run 2 copies of your app (high availability)
image - Your Docker image from Docker Hub
containerPort: 80 - App listens on port 80
resources - CPU/memory limits (prevents one app from using all resources)
Step 15: Create Kubernetes Service YAML
Run on MASTER NODE:

# Create service file
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
Service YAML Explanation:

type: NodePort - Expose app on a port on every node (30000-32767)
selector - Connect to pods with label app: e-learning
port: 80 - Service listens on port 80
targetPort: 80 - Forward to container port 80
nodePort: 30080 - Access app at http://<NODE_IP>:30080
Step 16: Deploy Application
Run on MASTER NODE:

# Apply deployment
kubectl apply -f deployment.yaml

# Apply service
kubectl apply -f service.yaml

# Check deployment status
kubectl get deployments
kubectl get pods
kubectl get services
Expected output:

NAME                    READY   STATUS    RESTARTS   AGE
e-learning-deployment   2/2     Running   0          1m

NAME                  TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
e-learning-service    NodePort   10.96.100.100   <none>        80:30080/TCP   1m
Step 17: Access Your Website
Open browser and visit:

http://<MASTER_PUBLIC_IP>:30080
http://<WORKER_PUBLIC_IP>:30080
✅ Your E-Learning website is now live!

📊 Monitoring Setup (Prometheus + Grafana)
Step 18: Install Helm (Package Manager for K8s)
Run on MASTER NODE:

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify
helm version
Step 19: Install Prometheus Stack
Run on MASTER NODE:

# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Install Prometheus + Grafana stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.service.type=NodePort \
  --set prometheus.service.nodePort=30090 \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=30030

# Wait for pods to start (takes 2-3 minutes)
kubectl get pods -n monitoring -w
Press Ctrl+C when all pods show Running

What this installs:

Prometheus - Metrics collection
Grafana - Visualization
Alertmanager - Alerts
Node Exporter - Node metrics
Kube State Metrics - K8s metrics
Step 20: Verify Monitoring Stack
Run on MASTER NODE:

# Check all monitoring components
kubectl get all -n monitoring

# Get Grafana admin password
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
Save the password! (Default username: admin)

✅ Verification & Access
Step 21: Access All Services
Your Application:

http://<MASTER_IP>:30080
http://<WORKER_IP>:30080
Prometheus UI:

http://<MASTER_IP>:30090
http://<WORKER_IP>:30090
Grafana UI:

http://<MASTER_IP>:30030
http://<WORKER_IP>:30030
Username: admin
Password: (from Step 20)
Step 22: Configure Grafana Dashboard
Login to Grafana (http://<MASTER_IP>:30030)

Prometheus is already configured as data source!

Go to: Configuration → Data Sources
You'll see Prometheus already connected
Import Pre-built Dashboard:

Click "+" → Import
Enter Dashboard ID: 15760 (Kubernetes cluster monitoring)
Click "Load"
Select "Prometheus" as data source
Click "Import"
You'll see:

Cluster CPU usage
Memory usage
Pod status
Network traffic
Node health
Import Another Dashboard for Pods:

Dashboard ID: 15759 (Kubernetes pods)
Shows individual pod metrics
Step 23: Useful Kubectl Commands
Run on MASTER NODE:

# View all pods
kubectl get pods -A

# View pods in default namespace
kubectl get pods

# View services
kubectl get svc

# View nodes
kubectl get nodes

# Describe pod (detailed info)
kubectl describe pod <pod-name>

# View pod logs
kubectl logs <pod-name>

# View pod logs (follow/live)
kubectl logs -f <pod-name>

# Delete pod (will auto-restart)
kubectl delete pod <pod-name>

# Scale deployment
kubectl scale deployment e-learning-deployment --replicas=3

# View deployment status
kubectl rollout status deployment e-learning-deployment

# View resource usage
kubectl top nodes
kubectl top pods
🔧 Common Errors & Fixes
Error 1: ImagePullBackOff
Symptom:

kubectl get pods
# Shows: ImagePullBackOff
Cause: Kubernetes can't download your Docker image

Fix:

# Check exact error
kubectl describe pod <pod-name>

# Common issues:
# 1. Wrong image name in deployment.yaml
# 2. Image is private (not public on Docker Hub)
# 3. Typo in image name

# Solution:
# Make image public on Docker Hub:
# - Go to hub.docker.com
# - Click your repository
# - Settings → Make Public

# Or update deployment with correct image name:
kubectl edit deployment e-learning-deployment
# Change image name, save, exit
Error 2: CrashLoopBackOff
Symptom:

kubectl get pods
# Shows: CrashLoopBackOff
Cause: Container starts but immediately crashes

Fix:

# Check logs
kubectl logs <pod-name>

# Common issues:
# 1. Wrong CMD in Dockerfile
# 2. Missing files
# 3. Port conflict

# Solution for Nginx:
# Ensure Dockerfile has:
# CMD ["nginx", "-g", "daemon off;"]

# Rebuild and push image:
docker build -t yourusername/e-learning:v2 .
docker push yourusername/e-learning:v2

# Update deployment:
kubectl set image deployment/e-learning-deployment e-learning=yourusername/e-learning:v2
Error 3: 403 Forbidden (Nginx)
Symptom: Website shows "403 Forbidden"

Cause: Nginx can't find index.html

Fix:

# Check Dockerfile COPY path
# Should be:
COPY . /usr/share/nginx/html/

# NOT:
COPY ./e-learning /usr/share/nginx/html/

# Rebuild:
docker build -t yourusername/e-learning:v3 .
docker push yourusername/e-learning:v3
kubectl set image deployment/e-learning-deployment e-learning=yourusername/e-learning:v3
Error 4: NodePort Not Accessible
Symptom: Can't access http://:30080

Fix:

# 1. Check security group has port 30080 open
# AWS Console → EC2 → Security Groups → Edit Inbound Rules
# Add: 30000-32767, TCP, 0.0.0.0/0

# 2. Check service is running
kubectl get svc

# 3. Check pods are running
kubectl get pods

# 4. Try from master node first
curl localhost:30080
Error 5: Worker Node Not Joining
Symptom: kubectl get nodes shows only master

Fix:

# On Master, generate new join command:
kubeadm token create --print-join-command

# Copy output, run on Worker with sudo:
sudo kubeadm join ...

# If still fails, reset worker and try again:
# On Worker:
sudo kubeadm reset
sudo systemctl restart containerd
# Then run join command again
Error 6: Prometheus/Grafana Pods Pending
Symptom: Monitoring pods stuck in "Pending" state

Fix:

# Check why:
kubectl describe pod <pod-name> -n monitoring

# Usually: Not enough resources
# Solution: Use t2.medium instances (not t2.micro)

# Or reduce resource requests:
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.resources.requests.memory=512Mi
🎤 Presentation Guide
Architecture Explanation (2 minutes)
Say this:

"I've deployed a complete DevOps pipeline for an E-Learning website using industry-standard tools.

Infrastructure: Two AWS EC2 instances - one Master node that manages the cluster, and one Worker node that runs the applications.

Containerization: I used Docker to package the frontend application into a container, making it portable and consistent across environments.

Orchestration: Kubernetes manages these containers - it automatically restarts failed pods, distributes traffic, and scales the application.

Monitoring: Prometheus collects metrics like CPU, memory, and network usage. Grafana visualizes this data in real-time dashboards.

Why Kubernetes? If I manually deployed on one server and it crashes, the website goes down. Kubernetes automatically detects failures and restarts containers on healthy nodes. It also makes scaling easy - I can go from 2 to 100 replicas with one command."

Demo Flow (3 minutes)
Show Architecture Diagram (draw on board or slide)

User → AWS → K8s Master → Worker Node → [Pod] [Pod]
                                           ↓
                                      Prometheus → Grafana
Show Website

Open: http://:30080
"This is the live website running in Kubernetes"
Show Kubernetes Dashboard

kubectl get pods
kubectl get nodes
kubectl get svc
"These commands show the cluster status"
Show Self-Healing

kubectl delete pod <pod-name>
kubectl get pods
"Watch - Kubernetes automatically creates a new pod"
Show Prometheus

Open: http://:30090
Click "Status" → "Targets"
"Prometheus is collecting metrics from all components"
Show Grafana

Open: http://:30030
Show dashboard 15760
"Real-time monitoring of CPU, memory, and network"
Key Points to Mention
Technical Skills Demonstrated:

Cloud infrastructure (AWS EC2)
Containerization (Docker)
Container orchestration (Kubernetes)
Monitoring and observability (Prometheus, Grafana)
Infrastructure as Code (YAML manifests)
CI/CD concepts (Docker Hub registry)
Real-World Applications:

This setup is used by companies like Netflix, Spotify, Airbnb
Kubernetes is the industry standard for container orchestration
Prometheus + Grafana is the most popular monitoring stack
Benefits:

High availability (multiple replicas)
Auto-scaling (can handle traffic spikes)
Self-healing (auto-restart failed containers)
Easy rollback (if new version has bugs)
Resource efficiency (containers are lightweight)
Questions You Might Get
Q: Why not deploy directly on EC2? A: Direct deployment doesn't provide auto-scaling, self-healing, or easy rollback. Kubernetes gives us all these features.

Q: Why use Docker? A: Docker ensures the app runs the same way in development, testing, and production. "It works on my machine" problem is solved.

Q: What if Master node fails? A: In production, we use multiple master nodes (HA setup). For this demo, we have one master to keep it simple.

Q: How does Kubernetes know a pod is unhealthy? A: Kubernetes uses liveness and readiness probes - it sends HTTP requests to the pod. If it doesn't respond, K8s restarts it.

Q: Can this handle 1 million users? A: Yes, by scaling replicas and adding more worker nodes. Kubernetes can scale to thousands of nodes.

📝 Quick Command Reference
Docker Commands
docker build -t image:tag .          # Build image
docker push image:tag                # Push to registry
docker images                        # List images
docker ps                            # List running containers
docker logs <container-id>           # View logs
Kubernetes Commands
kubectl get pods                     # List pods
kubectl get nodes                    # List nodes
kubectl get svc                      # List services
kubectl describe pod <name>          # Pod details
kubectl logs <pod-name>              # Pod logs
kubectl delete pod <name>            # Delete pod
kubectl apply -f file.yaml           # Apply config
kubectl scale deployment <name> --replicas=3  # Scale
Monitoring Commands
kubectl get pods -n monitoring       # Monitoring pods
kubectl logs -n monitoring <pod>     # Monitoring logs
kubectl top nodes                    # Node resource usage
kubectl top pods                     # Pod resource usage
🎯 Project Completion Checklist
 2 EC2 instances launched (t2.medium)
 Security groups configured (all required ports)
 Docker installed on both nodes
 Kubernetes installed on both nodes
 Cluster initialized (Master)
 Worker joined to cluster
 Application containerized (Dockerfile)
 Image pushed to Docker Hub
 Deployment YAML created and applied
 Service YAML created and applied
 Website accessible on NodePort
 Prometheus installed
 Grafana installed
 Grafana dashboard configured
 All pods running (kubectl get pods -A)
 Monitoring dashboards showing data
💡 Time-Saving Tips
Use copy-paste for long commands - Don't type manually
Keep both terminals open (Master and Worker) - Switch between them
Use kubectl get pods -w - Watch mode shows real-time updates
Bookmark IPs - Save Master/Worker IPs in notepad
Take screenshots - Capture working dashboards for presentation
Test before presentation - Run through demo once
🚀 Next Steps (After Presentation)
To make this production-ready:

Add HTTPS - Use cert-manager for SSL certificates
Use Ingress - Instead of NodePort (more professional)
Add CI/CD - GitHub Actions to auto-deploy on git push
Multi-Master Setup - High availability
Use Managed K8s - EKS, GKE, or AKS (easier management)
Add Logging - ELK stack or Loki
Add Alerts - Alertmanager notifications
Use Helm Charts - Package your app as Helm chart
📚 Resources
Kubernetes Docs: https://kubernetes.io/docs/
Docker Docs: https://docs.docker.com/
Prometheus Docs: https://prometheus.io/docs/
Grafana Dashboards: https://grafana.com/grafana/dashboards/
Good luck with your presentation! 🎉

Remember: The goal is to show you understand DevOps concepts and can implement them. Don't worry if something breaks during demo - explaining how you'd troubleshoot shows real understanding.
