# ⚡ Quick Start Guide (2-Hour Setup)

This is the fastest path to get your E-Learning project deployed with monitoring.

## 🎯 Prerequisites

- AWS Account
- Docker Hub account (free at hub.docker.com)
- Git Bash (Windows) or Terminal (Mac/Linux)
- 2 hours of time

## 📋 Step-by-Step Checklist

### Phase 1: AWS Setup (15 minutes)

- [ ] Launch 2 EC2 instances (t2.medium, Ubuntu 22.04)
  - Name: `k8s-master` and `k8s-worker`
- [ ] Create security group with ALL required ports (see main README)
- [ ] Download key pair: `k8s-key.pem`
- [ ] Note down both Public IPs

### Phase 2: Master Node Setup (20 minutes)

```bash
# Connect to Master
ssh -i "k8s-key.pem" ubuntu@<MASTER_IP>

# Download and run setup script
curl -O https://raw.githubusercontent.com/Rachna0612/E-LEARNING/main/devops-deployment/scripts/setup-master.sh
chmod +x setup-master.sh
./setup-master.sh

# SAVE THE JOIN COMMAND that appears at the end!
```

- [ ] Master setup complete
- [ ] Join command saved

### Phase 3: Worker Node Setup (15 minutes)

```bash
# Open NEW terminal, connect to Worker
ssh -i "k8s-key.pem" ubuntu@<WORKER_IP>

# Download and run setup script
curl -O https://raw.githubusercontent.com/Rachna0612/E-LEARNING/main/devops-deployment/scripts/setup-worker.sh
chmod +x setup-worker.sh
./setup-worker.sh

# Run the join command from Master (with sudo)
sudo kubeadm join ...
```

- [ ] Worker setup complete
- [ ] Worker joined cluster

**Verify on Master:**
```bash
kubectl get nodes
# Both nodes should show "Ready"
```

### Phase 4: Deploy Application (20 minutes)

**On Master Node:**

```bash
# Download deploy script
curl -O https://raw.githubusercontent.com/Rachna0612/E-LEARNING/main/devops-deployment/scripts/deploy-app.sh
chmod +x deploy-app.sh

# Edit the script to add your Docker Hub username
nano deploy-app.sh
# Change: DOCKER_USERNAME="yourusername"
# Save: Ctrl+X, Y, Enter

# Run deployment
./deploy-app.sh
```

- [ ] Docker image built
- [ ] Image pushed to Docker Hub
- [ ] App deployed to Kubernetes
- [ ] Website accessible at http://<NODE_IP>:30080

### Phase 5: Install Monitoring (25 minutes)

**On Master Node:**

```bash
# Download monitoring script
curl -O https://raw.githubusercontent.com/Rachna0612/E-LEARNING/main/devops-deployment/scripts/install-monitoring.sh
chmod +x install-monitoring.sh

# Run installation
./install-monitoring.sh
```

- [ ] Prometheus installed
- [ ] Grafana installed
- [ ] Both accessible via browser

### Phase 6: Configure Grafana (15 minutes)

1. **Open Grafana:** http://<MASTER_IP>:30030
   - Username: `admin`
   - Password: `admin123`

2. **Import Dashboard:**
   - Click "+" → Import
   - Enter ID: `15760`
   - Click Load → Import

3. **Import Pod Dashboard:**
   - Click "+" → Import
   - Enter ID: `15759`
   - Click Load → Import

- [ ] Grafana dashboards configured
- [ ] Metrics visible

### Phase 7: Verification (10 minutes)

**Check everything works:**

```bash
# On Master Node
kubectl get nodes
kubectl get pods -A
kubectl get svc
```

**Open in browser:**
- [ ] Website: http://<NODE_IP>:30080
- [ ] Prometheus: http://<NODE_IP>:30090
- [ ] Grafana: http://<NODE_IP>:30030

### Phase 8: Prepare Presentation (15 minutes)

- [ ] Take screenshots of:
  - Website running
  - Kubernetes pods
  - Prometheus targets
  - Grafana dashboards
- [ ] Practice demo flow
- [ ] Review architecture explanation

## 🚨 Common Issues

### Issue: Worker not joining

**Solution:**
```bash
# On Master, generate new join command
kubeadm token create --print-join-command

# On Worker, reset and try again
sudo kubeadm reset
sudo systemctl restart containerd
# Run new join command
```

### Issue: Pods stuck in Pending

**Solution:**
```bash
# Check what's wrong
kubectl describe pod <pod-name>

# Usually: not enough resources
# Make sure you're using t2.medium (not t2.micro)
```

### Issue: Can't access website

**Solution:**
1. Check security group has port 30080 open
2. Check pods are running: `kubectl get pods`
3. Check service: `kubectl get svc`
4. Try from master: `curl localhost:30080`

### Issue: ImagePullBackOff

**Solution:**
1. Make Docker Hub repository public
2. Check image name in deployment.yaml
3. Verify image exists: `docker images`

## 📊 Time Breakdown

| Phase | Time | Can Skip? |
|-------|------|-----------|
| AWS Setup | 15 min | No |
| Master Setup | 20 min | No |
| Worker Setup | 15 min | No |
| Deploy App | 20 min | No |
| Monitoring | 25 min | Yes (if time-constrained) |
| Grafana Config | 15 min | Yes (if time-constrained) |
| Verification | 10 min | No |
| Presentation Prep | 15 min | No |
| **Total** | **2h 15min** | |

**If you only have 90 minutes:** Skip Grafana dashboard configuration, just show Prometheus.

## 🎤 Quick Demo Script

**1. Show Architecture (30 seconds)**
"I've deployed a frontend application using Kubernetes on AWS with Prometheus monitoring."

**2. Show Website (30 seconds)**
Open: http://<IP>:30080
"This is the live E-Learning website running in Kubernetes pods."

**3. Show Kubernetes (1 minute)**
```bash
kubectl get nodes
kubectl get pods
kubectl get svc
```
"Two nodes, multiple pods for high availability."

**4. Show Self-Healing (1 minute)**
```bash
kubectl delete pod <pod-name>
kubectl get pods
```
"Kubernetes automatically recreates failed pods."

**5. Show Monitoring (1 minute)**
Open Prometheus: http://<IP>:30090
Open Grafana: http://<IP>:30030
"Real-time monitoring of all cluster resources."

**Total demo time: 4 minutes**

## 🎯 Success Criteria

You're ready for presentation when:

- [ ] Both nodes show "Ready"
- [ ] All pods show "Running"
- [ ] Website loads in browser
- [ ] Prometheus shows targets "UP"
- [ ] Grafana shows metrics
- [ ] You can explain why you used each tool
- [ ] You can demonstrate self-healing

## 💡 Pro Tips

1. **Keep terminals open** - Don't close Master/Worker SSH sessions
2. **Bookmark IPs** - Save all URLs in notepad
3. **Screenshot everything** - Capture working state
4. **Test before class** - Run through demo once
5. **Have backup plan** - If live demo fails, show screenshots

## 📞 Emergency Troubleshooting

**If everything breaks:**

1. Check nodes: `kubectl get nodes`
2. Check pods: `kubectl get pods -A`
3. Check logs: `kubectl logs <pod-name>`
4. Restart pod: `kubectl delete pod <pod-name>`
5. Check security groups in AWS

**Still broken?**
- Destroy and recreate cluster (you have scripts!)
- Or show screenshots and explain what you did

## 🎓 Key Concepts to Explain

**Kubernetes:**
"Manages containers automatically - restarts failures, scales apps, distributes traffic."

**Docker:**
"Packages app into container - runs same way everywhere."

**Prometheus:**
"Collects metrics from all components - CPU, memory, network."

**Grafana:**
"Visualizes Prometheus data in dashboards."

**Why not just EC2?**
"No auto-scaling, no self-healing, manual management. Kubernetes does this automatically."

---

**Good luck! You've got this! 🚀**
