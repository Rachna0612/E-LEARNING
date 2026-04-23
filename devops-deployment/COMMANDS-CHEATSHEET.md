# 📝 Commands Cheat Sheet

Quick reference for all commands used in this project.

## 🔧 AWS & SSH Commands

### Connect to Instances
```bash
# Connect to Master Node
ssh -i "k8s-key.pem" ubuntu@<MASTER_PUBLIC_IP>

# Connect to Worker Node
ssh -i "k8s-key.pem" ubuntu@<WORKER_PUBLIC_IP>

# Fix key permissions (if needed)
chmod 400 k8s-key.pem

# Copy file to instance
scp -i "k8s-key.pem" file.txt ubuntu@<IP>:~/

# Copy file from instance
scp -i "k8s-key.pem" ubuntu@<IP>:~/file.txt ./
```

## 🐳 Docker Commands

### Basic Docker
```bash
# Check Docker version
docker --version

# List images
docker images

# List running containers
docker ps

# List all containers
docker ps -a

# Remove image
docker rmi <image-id>

# Remove container
docker rm <container-id>

# Remove all stopped containers
docker container prune
```

### Build & Push
```bash
# Build image
docker build -t username/image:tag .

# Build with no cache
docker build --no-cache -t username/image:tag .

# Tag image
docker tag old-name:tag new-name:tag

# Login to Docker Hub
docker login

# Push image
docker push username/image:tag

# Pull image
docker pull username/image:tag
```

### Run & Debug
```bash
# Run container
docker run -d -p 8080:80 username/image:tag

# Run interactively
docker run -it username/image:tag /bin/sh

# Execute command in running container
docker exec -it <container-id> /bin/sh

# View logs
docker logs <container-id>

# Follow logs
docker logs -f <container-id>

# Inspect container
docker inspect <container-id>

# Stop container
docker stop <container-id>

# Start container
docker start <container-id>
```

## ☸️ Kubernetes - Cluster Management

### Cluster Info
```bash
# Get cluster info
kubectl cluster-info

# Get cluster version
kubectl version

# Get cluster nodes
kubectl get nodes

# Get node details
kubectl describe node <node-name>

# Get all resources
kubectl get all -A

# Get component status
kubectl get componentstatuses
```

### Node Management
```bash
# Label node
kubectl label nodes <node-name> key=value

# Remove label
kubectl label nodes <node-name> key-

# Taint node
kubectl taint nodes <node-name> key=value:NoSchedule

# Remove taint
kubectl taint nodes <node-name> key:NoSchedule-

# Drain node (evict pods)
kubectl drain <node-name> --ignore-daemonsets

# Uncordon node (allow scheduling)
kubectl uncordon <node-name>

# Cordon node (prevent scheduling)
kubectl cordon <node-name>
```

## ☸️ Kubernetes - Pods

### View Pods
```bash
# Get pods in default namespace
kubectl get pods

# Get pods in all namespaces
kubectl get pods -A

# Get pods with labels
kubectl get pods --show-labels

# Get pods with wide output (shows node, IP)
kubectl get pods -o wide

# Get pods in specific namespace
kubectl get pods -n <namespace>

# Watch pods (auto-refresh)
kubectl get pods -w

# Get pod YAML
kubectl get pod <pod-name> -o yaml

# Get pod JSON
kubectl get pod <pod-name> -o json
```

### Pod Details
```bash
# Describe pod (detailed info)
kubectl describe pod <pod-name>

# Get pod logs
kubectl logs <pod-name>

# Get logs from previous container
kubectl logs <pod-name> --previous

# Follow logs (live)
kubectl logs -f <pod-name>

# Get logs from specific container
kubectl logs <pod-name> -c <container-name>

# Get logs with timestamps
kubectl logs <pod-name> --timestamps

# Get last 100 lines
kubectl logs <pod-name> --tail=100
```

### Pod Operations
```bash
# Delete pod
kubectl delete pod <pod-name>

# Force delete pod
kubectl delete pod <pod-name> --grace-period=0 --force

# Execute command in pod
kubectl exec <pod-name> -- <command>

# Interactive shell in pod
kubectl exec -it <pod-name> -- /bin/sh

# Copy file to pod
kubectl cp file.txt <pod-name>:/path/

# Copy file from pod
kubectl cp <pod-name>:/path/file.txt ./

# Port forward to pod
kubectl port-forward <pod-name> 8080:80
```

## ☸️ Kubernetes - Deployments

### View Deployments
```bash
# Get deployments
kubectl get deployments

# Get deployment details
kubectl describe deployment <deployment-name>

# Get deployment YAML
kubectl get deployment <deployment-name> -o yaml

# Get deployment status
kubectl rollout status deployment/<deployment-name>
```

### Create & Update
```bash
# Create deployment from YAML
kubectl apply -f deployment.yaml

# Create deployment from command
kubectl create deployment <name> --image=<image>

# Update image
kubectl set image deployment/<name> <container>=<new-image>

# Edit deployment
kubectl edit deployment <deployment-name>

# Scale deployment
kubectl scale deployment <deployment-name> --replicas=5

# Autoscale deployment
kubectl autoscale deployment <name> --min=2 --max=10 --cpu-percent=80
```

### Rollout Management
```bash
# Check rollout status
kubectl rollout status deployment/<name>

# View rollout history
kubectl rollout history deployment/<name>

# Rollback to previous version
kubectl rollout undo deployment/<name>

# Rollback to specific revision
kubectl rollout undo deployment/<name> --to-revision=2

# Pause rollout
kubectl rollout pause deployment/<name>

# Resume rollout
kubectl rollout resume deployment/<name>

# Restart deployment (recreate pods)
kubectl rollout restart deployment/<name>
```

### Delete Deployment
```bash
# Delete deployment
kubectl delete deployment <deployment-name>

# Delete deployment from file
kubectl delete -f deployment.yaml
```

## ☸️ Kubernetes - Services

### View Services
```bash
# Get services
kubectl get svc

# Get service details
kubectl describe svc <service-name>

# Get service YAML
kubectl get svc <service-name> -o yaml

# Get service endpoints
kubectl get endpoints <service-name>
```

### Create & Update
```bash
# Create service from YAML
kubectl apply -f service.yaml

# Expose deployment as service
kubectl expose deployment <name> --port=80 --target-port=80 --type=NodePort

# Edit service
kubectl edit svc <service-name>
```

### Delete Service
```bash
# Delete service
kubectl delete svc <service-name>

# Delete service from file
kubectl delete -f service.yaml
```

## ☸️ Kubernetes - ConfigMaps & Secrets

### ConfigMaps
```bash
# Create ConfigMap from file
kubectl create configmap <name> --from-file=file.txt

# Create ConfigMap from literal
kubectl create configmap <name> --from-literal=key=value

# Get ConfigMaps
kubectl get configmaps

# Describe ConfigMap
kubectl describe configmap <name>

# Delete ConfigMap
kubectl delete configmap <name>
```

### Secrets
```bash
# Create Secret from literal
kubectl create secret generic <name> --from-literal=password=secret123

# Create Secret from file
kubectl create secret generic <name> --from-file=ssh-key=~/.ssh/id_rsa

# Create Docker registry secret
kubectl create secret docker-registry <name> \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email>

# Get Secrets
kubectl get secrets

# Describe Secret
kubectl describe secret <name>

# Get Secret value (base64 encoded)
kubectl get secret <name> -o yaml

# Decode Secret value
kubectl get secret <name> -o jsonpath="{.data.password}" | base64 --decode

# Delete Secret
kubectl delete secret <name>
```

## ☸️ Kubernetes - Namespaces

### Namespace Operations
```bash
# Get namespaces
kubectl get namespaces

# Create namespace
kubectl create namespace <name>

# Delete namespace
kubectl delete namespace <name>

# Set default namespace
kubectl config set-context --current --namespace=<name>

# Get resources in namespace
kubectl get all -n <namespace>
```

## ☸️ Kubernetes - Resource Management

### Resource Usage
```bash
# Get node resource usage
kubectl top nodes

# Get pod resource usage
kubectl top pods

# Get pod resource usage in namespace
kubectl top pods -n <namespace>

# Get pod resource usage with containers
kubectl top pods --containers
```

### Resource Quotas
```bash
# Get resource quotas
kubectl get resourcequota

# Describe resource quota
kubectl describe resourcequota <name>
```

## ☸️ Kubernetes - Debugging

### Events
```bash
# Get events
kubectl get events

# Get events sorted by time
kubectl get events --sort-by=.metadata.creationTimestamp

# Get events for specific resource
kubectl get events --field-selector involvedObject.name=<pod-name>

# Watch events
kubectl get events -w
```

### Troubleshooting
```bash
# Check pod status
kubectl get pods

# Describe pod (see events)
kubectl describe pod <pod-name>

# Get pod logs
kubectl logs <pod-name>

# Get previous pod logs
kubectl logs <pod-name> --previous

# Execute command in pod
kubectl exec -it <pod-name> -- /bin/sh

# Test DNS
kubectl run test-dns --image=busybox --rm -it -- nslookup kubernetes.default

# Test connectivity
kubectl run test-curl --image=curlimages/curl --rm -it -- curl http://service-name

# Get API resources
kubectl api-resources

# Explain resource
kubectl explain pod
kubectl explain pod.spec.containers
```

## 🎛️ Kubeadm Commands

### Cluster Initialization
```bash
# Initialize cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Initialize with specific API server address
sudo kubeadm init --apiserver-advertise-address=<IP> --pod-network-cidr=10.244.0.0/16

# Generate join command
kubeadm token create --print-join-command

# List tokens
kubeadm token list

# Create new token
kubeadm token create

# Delete token
kubeadm token delete <token>
```

### Cluster Management
```bash
# Join worker to cluster
sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

# Reset node (remove from cluster)
sudo kubeadm reset -f

# Upgrade cluster
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.28.0
```

## 📦 Helm Commands

### Helm Basics
```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Check Helm version
helm version

# Add repository
helm repo add <name> <url>

# Update repositories
helm repo update

# List repositories
helm repo list

# Remove repository
helm repo remove <name>

# Search charts
helm search repo <keyword>
```

### Install & Manage
```bash
# Install chart
helm install <release-name> <chart-name>

# Install with custom values
helm install <release-name> <chart-name> -f values.yaml

# Install with set values
helm install <release-name> <chart-name> --set key=value

# Install in namespace
helm install <release-name> <chart-name> -n <namespace>

# List releases
helm list

# List releases in all namespaces
helm list -A

# Get release status
helm status <release-name>

# Get release values
helm get values <release-name>

# Upgrade release
helm upgrade <release-name> <chart-name>

# Rollback release
helm rollback <release-name> <revision>

# Uninstall release
helm uninstall <release-name>
```

## 📊 Monitoring Commands

### Prometheus
```bash
# Get Prometheus pods
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus

# Get Prometheus service
kubectl get svc -n monitoring prometheus-kube-prometheus-prometheus

# Port forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Check Prometheus config
kubectl get configmap -n monitoring prometheus-kube-prometheus-prometheus -o yaml
```

### Grafana
```bash
# Get Grafana pods
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# Get Grafana service
kubectl get svc -n monitoring prometheus-grafana

# Get Grafana password
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Port forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Reset Grafana password
kubectl delete secret prometheus-grafana -n monitoring
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=newpassword
```

## 🔧 System Commands

### System Info
```bash
# Check OS version
lsb_release -a

# Check kernel version
uname -r

# Check CPU info
lscpu

# Check memory
free -h

# Check disk space
df -h

# Check network interfaces
ip addr show

# Check open ports
sudo netstat -tulpn

# Check running processes
ps aux

# Check system load
top
htop
```

### Service Management
```bash
# Check service status
sudo systemctl status <service>

# Start service
sudo systemctl start <service>

# Stop service
sudo systemctl stop <service>

# Restart service
sudo systemctl restart <service>

# Enable service (start on boot)
sudo systemctl enable <service>

# Disable service
sudo systemctl disable <service>

# View service logs
sudo journalctl -u <service>

# Follow service logs
sudo journalctl -u <service> -f
```

### Common Services
```bash
# Docker
sudo systemctl status docker
sudo systemctl restart docker

# Containerd
sudo systemctl status containerd
sudo systemctl restart containerd

# Kubelet
sudo systemctl status kubelet
sudo systemctl restart kubelet
```

## 🔍 Useful One-Liners

### Quick Checks
```bash
# Check if all pods are running
kubectl get pods -A | grep -v Running

# Count pods by status
kubectl get pods -A --no-headers | awk '{print $4}' | sort | uniq -c

# Get pod IPs
kubectl get pods -o wide | awk '{print $1, $6}'

# Get images used in cluster
kubectl get pods -A -o jsonpath="{.items[*].spec.containers[*].image}" | tr -s '[[:space:]]' '\n' | sort | uniq

# Get pods not in Running state
kubectl get pods -A --field-selector=status.phase!=Running

# Get pods with high restart count
kubectl get pods -A --sort-by=.status.containerStatuses[0].restartCount

# Delete all pods in namespace
kubectl delete pods --all -n <namespace>

# Delete all evicted pods
kubectl get pods -A | grep Evicted | awk '{print $2, $1}' | xargs -n2 kubectl delete pod -n

# Get resource requests/limits
kubectl get pods -o custom-columns=NAME:.metadata.name,CPU_REQ:.spec.containers[*].resources.requests.cpu,MEM_REQ:.spec.containers[*].resources.requests.memory
```

### Monitoring
```bash
# Watch pod status
watch kubectl get pods

# Watch node status
watch kubectl get nodes

# Watch events
kubectl get events -w

# Get pod CPU/Memory usage
kubectl top pods --sort-by=cpu
kubectl top pods --sort-by=memory

# Get node CPU/Memory usage
kubectl top nodes
```

### Cleanup
```bash
# Delete all resources in namespace
kubectl delete all --all -n <namespace>

# Delete completed pods
kubectl delete pods --field-selector=status.phase==Succeeded

# Delete failed pods
kubectl delete pods --field-selector=status.phase==Failed

# Prune unused Docker images
docker image prune -a

# Clean up Docker system
docker system prune -a --volumes
```

## 📋 Quick Reference

### Port Numbers
```
22     - SSH
80     - HTTP
443    - HTTPS
3000   - Grafana
6443   - Kubernetes API
9090   - Prometheus
10250  - Kubelet
30000-32767 - NodePort range
```

### Common Paths
```
/etc/kubernetes/          - Kubernetes config
/etc/kubernetes/manifests - Static pod manifests
/var/lib/kubelet/         - Kubelet data
/var/lib/etcd/            - etcd data
~/.kube/config            - kubectl config
/etc/docker/              - Docker config
/etc/containerd/          - Containerd config
```

### Environment Variables
```bash
# Set kubectl namespace
export NAMESPACE=default

# Set kubeconfig
export KUBECONFIG=~/.kube/config

# Set Docker Hub username
export DOCKER_USERNAME=yourusername
```

### Aliases (Add to ~/.bashrc)
```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
alias ka='kubectl apply -f'
alias kdel='kubectl delete'
```

---

**💡 Tip:** Bookmark this page for quick reference during your project!

**🔖 Pro Tip:** Use `kubectl explain <resource>` to get documentation for any Kubernetes resource.

Example:
```bash
kubectl explain pod
kubectl explain pod.spec
kubectl explain pod.spec.containers
```
