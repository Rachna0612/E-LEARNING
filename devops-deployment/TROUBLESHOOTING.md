# 🔧 Troubleshooting Guide

Complete guide to fix common issues in your DevOps deployment.

## 🚨 Quick Diagnosis

**Run these commands first:**

```bash
# Check cluster health
kubectl get nodes
kubectl get pods -A
kubectl cluster-info

# Check specific namespace
kubectl get pods
kubectl get svc
kubectl get deployments

# Check system pods
kubectl get pods -n kube-system
kubectl get pods -n monitoring
```

---

## 1. Node Issues

### Issue: Node shows "NotReady"

**Symptoms:**
```bash
kubectl get nodes
# NAME         STATUS     ROLES
# k8s-master   NotReady   control-plane
```

**Diagnosis:**
```bash
kubectl describe node <node-name>
```

**Common Causes & Fixes:**

**A. Network plugin not installed**
```bash
# Install Flannel
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Wait 30 seconds
kubectl get nodes
```

**B. Kubelet not running**
```bash
# Check kubelet status
sudo systemctl status kubelet

# Restart kubelet
sudo systemctl restart kubelet

# Check logs
sudo journalctl -u kubelet -f
```

**C. Containerd issues**
```bash
# Restart containerd
sudo systemctl restart containerd
sudo systemctl restart kubelet
```

**D. Swap not disabled**
```bash
# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Restart kubelet
sudo systemctl restart kubelet
```

### Issue: Worker node not joining cluster

**Symptoms:**
```bash
kubectl get nodes
# Only master node appears
```

**Fix 1: Generate new join token**
```bash
# On Master Node
kubeadm token create --print-join-command

# Copy the output, run on Worker with sudo
sudo kubeadm join 172.31.x.x:6443 --token abc... --discovery-token-ca-cert-hash sha256:xyz...
```

**Fix 2: Reset worker and rejoin**
```bash
# On Worker Node
sudo kubeadm reset -f
sudo systemctl restart containerd
sudo systemctl restart kubelet

# Run join command again
sudo kubeadm join ...
```

**Fix 3: Check connectivity**
```bash
# On Worker, test connection to Master
telnet <MASTER_PRIVATE_IP> 6443

# If fails, check security groups
# Master security group must allow port 6443 from Worker
```

---

## 2. Pod Issues

### Issue: ImagePullBackOff

**Symptoms:**
```bash
kubectl get pods
# NAME                    READY   STATUS             RESTARTS
# e-learning-xxx          0/1     ImagePullBackOff   0
```

**Diagnosis:**
```bash
kubectl describe pod <pod-name>
# Look for: Failed to pull image
```

**Common Causes & Fixes:**

**A. Image doesn't exist**
```bash
# Check image name in deployment
kubectl get deployment e-learning-deployment -o yaml | grep image:

# Verify image exists on Docker Hub
# Go to: https://hub.docker.com/r/yourusername/e-learning
```

**B. Image is private**
```bash
# Make image public on Docker Hub:
# 1. Go to hub.docker.com
# 2. Click your repository
# 3. Settings → Make Public

# Or create image pull secret:
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<your-username> \
  --docker-password=<your-password> \
  --docker-email=<your-email>

# Update deployment to use secret
kubectl edit deployment e-learning-deployment
# Add under spec.template.spec:
#   imagePullSecrets:
#   - name: regcred
```

**C. Wrong image name**
```bash
# Update deployment with correct image
kubectl set image deployment/e-learning-deployment \
  e-learning=yourusername/e-learning:v1

# Or edit directly
kubectl edit deployment e-learning-deployment
```

### Issue: CrashLoopBackOff

**Symptoms:**
```bash
kubectl get pods
# NAME                    READY   STATUS              RESTARTS
# e-learning-xxx          0/1     CrashLoopBackOff    5
```

**Diagnosis:**
```bash
# Check pod logs
kubectl logs <pod-name>

# Check previous logs (if pod restarted)
kubectl logs <pod-name> --previous

# Describe pod
kubectl describe pod <pod-name>
```

**Common Causes & Fixes:**

**A. Application error**
```bash
# For Nginx, common issues:
# 1. index.html not found
# 2. Wrong file permissions
# 3. Port already in use

# Check Dockerfile COPY path
# Should be: COPY e-learning/ /usr/share/nginx/html/
# NOT: COPY . /usr/share/nginx/html/e-learning/

# Rebuild image
docker build -t yourusername/e-learning:v2 .
docker push yourusername/e-learning:v2

# Update deployment
kubectl set image deployment/e-learning-deployment \
  e-learning=yourusername/e-learning:v2
```

**B. Resource limits too low**
```bash
# Increase resource limits
kubectl edit deployment e-learning-deployment

# Change:
# resources:
#   limits:
#     memory: "512Mi"  # Increase from 256Mi
#     cpu: "500m"      # Increase from 200m
```

**C. Missing environment variables**
```bash
# Add environment variables to deployment
kubectl edit deployment e-learning-deployment

# Add under containers:
# env:
# - name: ENV_VAR_NAME
#   value: "value"
```

### Issue: Pods stuck in Pending

**Symptoms:**
```bash
kubectl get pods
# NAME                    READY   STATUS    RESTARTS
# e-learning-xxx          0/1     Pending   0
```

**Diagnosis:**
```bash
kubectl describe pod <pod-name>
# Look for: FailedScheduling
```

**Common Causes & Fixes:**

**A. Insufficient resources**
```bash
# Check node resources
kubectl describe nodes

# Look for: Allocated resources
# If CPU/Memory is at 100%, you need:

# Option 1: Reduce resource requests
kubectl edit deployment e-learning-deployment
# Reduce requests.memory and requests.cpu

# Option 2: Add more worker nodes
# Launch new EC2 instance, join to cluster

# Option 3: Use larger instance type
# Change from t2.micro to t2.medium
```

**B. Node selector mismatch**
```bash
# Check if deployment has node selector
kubectl get deployment e-learning-deployment -o yaml | grep nodeSelector

# If present, remove it or add matching label to node
kubectl label nodes <node-name> <key>=<value>
```

**C. Taints on nodes**
```bash
# Check node taints
kubectl describe node <node-name> | grep Taints

# Remove taint if needed
kubectl taint nodes <node-name> <taint-key>-
```

### Issue: Pods in Terminating state (stuck)

**Symptoms:**
```bash
kubectl get pods
# NAME                    READY   STATUS        RESTARTS
# e-learning-xxx          1/1     Terminating   0
# (Stuck for minutes)
```

**Fix:**
```bash
# Force delete pod
kubectl delete pod <pod-name> --grace-period=0 --force

# If still stuck, delete from etcd
kubectl patch pod <pod-name> -p '{"metadata":{"finalizers":null}}'
```

---

## 3. Service Issues

### Issue: Cannot access application via NodePort

**Symptoms:**
- Browser shows "Connection refused" or timeout
- http://<NODE_IP>:30080 doesn't work

**Diagnosis:**
```bash
# Check service exists
kubectl get svc

# Check service details
kubectl describe svc e-learning-service

# Check pods are running
kubectl get pods

# Test from inside cluster
kubectl run test-pod --image=busybox --rm -it -- wget -O- http://e-learning-service
```

**Common Causes & Fixes:**

**A. Security group not configured**
```bash
# AWS Console → EC2 → Security Groups
# Add inbound rule:
# Type: Custom TCP
# Port Range: 30000-32767
# Source: 0.0.0.0/0
```

**B. Service selector doesn't match pods**
```bash
# Check service selector
kubectl get svc e-learning-service -o yaml | grep selector -A 2

# Check pod labels
kubectl get pods --show-labels

# They must match! If not, fix deployment labels:
kubectl edit deployment e-learning-deployment
```

**C. Wrong NodePort**
```bash
# Check actual NodePort
kubectl get svc e-learning-service

# Use the port shown under PORT(S)
# Example: 80:30080/TCP means use port 30080
```

**D. Pods not ready**
```bash
# Check pod status
kubectl get pods

# If not Running, fix pod issues first (see above)
```

**E. Firewall on node**
```bash
# Check if firewall is blocking
sudo iptables -L -n | grep 30080

# Disable firewall (Ubuntu)
sudo ufw disable

# Or allow port
sudo ufw allow 30080/tcp
```

### Issue: Service has no endpoints

**Symptoms:**
```bash
kubectl describe svc e-learning-service
# Endpoints: <none>
```

**Fix:**
```bash
# Service selector doesn't match any pods
# Check labels match:

kubectl get svc e-learning-service -o yaml | grep selector -A 2
kubectl get pods --show-labels

# Fix deployment labels:
kubectl edit deployment e-learning-deployment
# Ensure labels match service selector
```

---

## 4. Deployment Issues

### Issue: Deployment not creating pods

**Symptoms:**
```bash
kubectl get deployments
# NAME                    READY   UP-TO-DATE   AVAILABLE
# e-learning-deployment   0/2     0            0
```

**Diagnosis:**
```bash
kubectl describe deployment e-learning-deployment
kubectl get replicasets
kubectl describe replicaset <replicaset-name>
```

**Fix:**
```bash
# Check for errors in deployment
kubectl get events --sort-by=.metadata.creationTimestamp

# Common issues:
# 1. Invalid image name
# 2. Invalid YAML syntax
# 3. Resource quota exceeded

# Delete and recreate deployment
kubectl delete deployment e-learning-deployment
kubectl apply -f deployment.yaml
```

### Issue: Rolling update stuck

**Symptoms:**
```bash
kubectl rollout status deployment/e-learning-deployment
# Waiting for deployment "e-learning-deployment" rollout to finish: 1 old replicas are pending termination...
```

**Fix:**
```bash
# Check what's wrong
kubectl describe deployment e-learning-deployment

# Force rollout
kubectl rollout restart deployment/e-learning-deployment

# Or rollback
kubectl rollout undo deployment/e-learning-deployment

# Check history
kubectl rollout history deployment/e-learning-deployment
```

---

## 5. Monitoring Issues

### Issue: Prometheus pods not starting

**Symptoms:**
```bash
kubectl get pods -n monitoring
# prometheus-xxx   0/1   Pending   0   5m
```

**Diagnosis:**
```bash
kubectl describe pod <prometheus-pod> -n monitoring
```

**Common Causes & Fixes:**

**A. Insufficient resources**
```bash
# Prometheus needs significant resources
# Use t2.medium or larger instances

# Or reduce resource requests:
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.resources.requests.memory=512Mi \
  --set prometheus.prometheusSpec.resources.requests.cpu=250m
```

**B. Storage issues**
```bash
# Check PVC status
kubectl get pvc -n monitoring

# If PVC is Pending, check storage class
kubectl get storageclass

# For AWS, ensure EBS CSI driver is installed
# Or disable persistence:
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.storageSpec=null
```

### Issue: Grafana login not working

**Symptoms:**
- Can't login to Grafana
- Forgot password

**Fix:**
```bash
# Get Grafana password
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Username is: admin

# Reset password:
kubectl delete secret prometheus-grafana -n monitoring
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=newpassword123
```

### Issue: Prometheus not scraping targets

**Symptoms:**
- Prometheus UI shows targets as "DOWN"
- No metrics in Grafana

**Diagnosis:**
```bash
# Check Prometheus targets
# Open: http://<NODE_IP>:30090/targets

# Check ServiceMonitor
kubectl get servicemonitor -n monitoring
```

**Fix:**
```bash
# Ensure pods have correct labels
kubectl get pods --show-labels

# Check ServiceMonitor selector matches
kubectl describe servicemonitor -n monitoring

# Restart Prometheus
kubectl delete pod -n monitoring -l app.kubernetes.io/name=prometheus
```

### Issue: Grafana shows "No data"

**Symptoms:**
- Grafana dashboard loads but shows no data

**Fix:**
```bash
# 1. Check Prometheus data source
# Grafana → Configuration → Data Sources
# Should show Prometheus as connected

# 2. Check Prometheus has data
# Open: http://<NODE_IP>:30090
# Run query: up
# Should show results

# 3. Check time range in Grafana
# Top right corner → Last 6 hours

# 4. Reimport dashboard
# Dashboard → Import → Enter ID: 15760
```

---

## 6. Docker Issues

### Issue: Docker build fails

**Symptoms:**
```bash
docker build -t image:tag .
# Error: COPY failed
```

**Fix:**
```bash
# Check Dockerfile path
# Ensure you're in correct directory
pwd
ls -la

# Check COPY source exists
ls -la e-learning/

# Common fixes:
# 1. Wrong COPY path in Dockerfile
# 2. Files not in expected location
# 3. .dockerignore excluding needed files

# Verify Dockerfile:
cat Dockerfile
```

### Issue: Docker push fails

**Symptoms:**
```bash
docker push username/image:tag
# denied: requested access to the resource is denied
```

**Fix:**
```bash
# Login to Docker Hub
docker login
# Enter username and password

# Check image name matches Docker Hub username
docker images

# Rename if needed
docker tag old-name:tag username/new-name:tag

# Push again
docker push username/new-name:tag
```

### Issue: Docker daemon not running

**Symptoms:**
```bash
docker ps
# Cannot connect to the Docker daemon
```

**Fix:**
```bash
# Start Docker
sudo systemctl start docker

# Enable Docker on boot
sudo systemctl enable docker

# Check status
sudo systemctl status docker

# If still fails, restart
sudo systemctl restart docker
```

---

## 7. Kubernetes Cluster Issues

### Issue: kubectl commands not working

**Symptoms:**
```bash
kubectl get nodes
# The connection to the server localhost:8080 was refused
```

**Fix:**
```bash
# Configure kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verify
kubectl cluster-info
```

### Issue: Cluster initialization failed

**Symptoms:**
```bash
sudo kubeadm init
# [ERROR ...]: various errors
```

**Fix:**
```bash
# Reset and try again
sudo kubeadm reset -f
sudo systemctl restart containerd
sudo systemctl restart kubelet

# Ensure prerequisites:
# 1. Swap disabled
sudo swapoff -a

# 2. Ports available
sudo netstat -tulpn | grep -E '6443|10250|10251|10252|2379|2380'

# 3. Containerd configured
sudo systemctl status containerd

# Initialize again
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

### Issue: CoreDNS pods in CrashLoopBackOff

**Symptoms:**
```bash
kubectl get pods -n kube-system
# coredns-xxx   0/1   CrashLoopBackOff
```

**Fix:**
```bash
# Usually caused by loop in /etc/resolv.conf

# Check
kubectl logs -n kube-system <coredns-pod>

# Fix: Edit CoreDNS ConfigMap
kubectl edit configmap coredns -n kube-system

# Remove or comment out the 'loop' line
# Or add:
# forward . 8.8.8.8 8.8.4.4

# Restart CoreDNS
kubectl delete pod -n kube-system -l k8s-app=kube-dns
```

---

## 8. Network Issues

### Issue: Pods can't communicate

**Symptoms:**
```bash
# Pod A can't reach Pod B
kubectl exec -it <pod-a> -- ping <pod-b-ip>
# Network unreachable
```

**Fix:**
```bash
# Check network plugin
kubectl get pods -n kube-system | grep flannel

# If not running, install Flannel
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Check CNI plugins
ls -la /opt/cni/bin/

# Restart network pods
kubectl delete pod -n kube-system -l app=flannel
```

### Issue: DNS not working in pods

**Symptoms:**
```bash
kubectl exec -it <pod> -- nslookup kubernetes.default
# Server: 10.96.0.10
# ** server can't find kubernetes.default: NXDOMAIN
```

**Fix:**
```bash
# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check DNS service
kubectl get svc -n kube-system kube-dns

# Test DNS from pod
kubectl run test-dns --image=busybox --rm -it -- nslookup kubernetes.default

# If fails, restart CoreDNS
kubectl delete pod -n kube-system -l k8s-app=kube-dns
```

---

## 9. AWS-Specific Issues

### Issue: Can't SSH to EC2 instance

**Symptoms:**
```bash
ssh -i key.pem ubuntu@<IP>
# Connection timed out
```

**Fix:**
```bash
# 1. Check security group allows SSH (port 22)
# AWS Console → EC2 → Security Groups
# Inbound rules must have: 22, TCP, 0.0.0.0/0

# 2. Check key permissions
chmod 400 key.pem

# 3. Check instance is running
# AWS Console → EC2 → Instances

# 4. Check public IP is correct
# Use Public IPv4 address, not Private

# 5. Try different SSH client
# Windows: Use Git Bash, not CMD
```

### Issue: Instance out of memory

**Symptoms:**
```bash
# SSH is slow or unresponsive
# Pods being evicted
```

**Fix:**
```bash
# Check memory
free -h

# Check what's using memory
top
# Press M to sort by memory

# If out of memory:
# 1. Use larger instance (t2.medium → t2.large)
# 2. Reduce pod resource requests
# 3. Reduce number of replicas
# 4. Add swap (not recommended for K8s)
```

---

## 10. Emergency Recovery

### Complete Cluster Reset

**If everything is broken:**

```bash
# On Master Node
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo rm -rf $HOME/.kube
sudo systemctl restart containerd
sudo systemctl restart kubelet

# On Worker Node
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo systemctl restart containerd
sudo systemctl restart kubelet

# Reinitialize cluster (Master)
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configure kubectl (Master)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install network plugin (Master)
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Get join command (Master)
kubeadm token create --print-join-command

# Join worker (Worker)
sudo kubeadm join ...

# Verify
kubectl get nodes
```

### Backup Important Data

**Before major changes:**

```bash
# Backup deployments
kubectl get deployments -o yaml > deployments-backup.yaml

# Backup services
kubectl get services -o yaml > services-backup.yaml

# Backup configmaps
kubectl get configmaps -o yaml > configmaps-backup.yaml

# Backup all resources
kubectl get all -o yaml > all-resources-backup.yaml
```

---

## 📞 Getting Help

### Useful Commands for Debugging

```bash
# Get all resources
kubectl get all -A

# Get events (recent issues)
kubectl get events --sort-by=.metadata.creationTimestamp

# Describe resource (detailed info)
kubectl describe <resource-type> <resource-name>

# Get logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # Previous container
kubectl logs <pod-name> -c <container-name>  # Specific container

# Execute command in pod
kubectl exec -it <pod-name> -- /bin/sh

# Port forward (test service locally)
kubectl port-forward svc/<service-name> 8080:80

# Get resource YAML
kubectl get <resource> <name> -o yaml

# Check resource usage
kubectl top nodes
kubectl top pods
```

### Log Locations

```bash
# Kubelet logs
sudo journalctl -u kubelet -f

# Containerd logs
sudo journalctl -u containerd -f

# Docker logs
sudo journalctl -u docker -f

# System logs
sudo tail -f /var/log/syslog
```

### Kubernetes Documentation

- Official Docs: https://kubernetes.io/docs/
- Troubleshooting: https://kubernetes.io/docs/tasks/debug/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

**Remember:** Most issues are fixable! Stay calm, read error messages carefully, and debug systematically.
