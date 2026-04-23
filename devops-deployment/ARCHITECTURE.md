# 🏗️ Architecture Documentation

Complete technical architecture of the E-Learning DevOps deployment.

## 📊 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet Users                           │
│                    (HTTP/HTTPS Requests)                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      AWS Cloud (us-east-1)                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              VPC (Virtual Private Cloud)                   │  │
│  │  ┌─────────────────────┐    ┌─────────────────────┐      │  │
│  │  │   EC2 Instance      │    │   EC2 Instance      │      │  │
│  │  │   (t2.medium)       │    │   (t2.medium)       │      │  │
│  │  │                     │    │                     │      │  │
│  │  │  ┌──────────────┐   │    │  ┌──────────────┐  │      │  │
│  │  │  │ Master Node  │   │    │  │ Worker Node  │  │      │  │
│  │  │  │              │   │    │  │              │  │      │  │
│  │  │  │ • API Server │◄──┼────┼──┤ • Kubelet    │  │      │  │
│  │  │  │ • Scheduler  │   │    │  │ • Kube-proxy │  │      │  │
│  │  │  │ • Controller │   │    │  │ • Container  │  │      │  │
│  │  │  │ • etcd       │   │    │  │   Runtime    │  │      │  │
│  │  │  │ • Kubelet    │   │    │  │              │  │      │  │
│  │  │  └──────────────┘   │    │  └──────────────┘  │      │  │
│  │  │                     │    │                     │      │  │
│  │  │  Pods:              │    │  Pods:              │      │  │
│  │  │  • Prometheus       │    │  • E-Learning (×2)  │      │  │
│  │  │  • Grafana          │    │  • Node Exporter    │      │  │
│  │  │  • Alertmanager     │    │                     │      │  │
│  │  └─────────────────────┘    └─────────────────────┘      │  │
│  │                                                            │  │
│  │  Security Group: k8s-security-group                       │  │
│  │  Ports: 22, 80, 443, 6443, 10250, 30000-32767, 9090, 3000│  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Docker Hub (Container Registry)               │
│                  yourusername/e-learning:v1                      │
└─────────────────────────────────────────────────────────────────┘
```

## 🔄 Request Flow

### User Request Flow

```
1. User enters: http://<NODE_IP>:30080
                     │
                     ▼
2. Request hits AWS Security Group
   ├─ Port 30080 allowed? ✓
   └─ Forward to EC2 instance
                     │
                     ▼
3. Request reaches Kubernetes NodePort Service
   ├─ Service: e-learning-service
   ├─ Type: NodePort
   ├─ Port: 30080
   └─ Selector: app=e-learning
                     │
                     ▼
4. Service load-balances to Pod
   ├─ Pod 1: e-learning-deployment-abc123
   ├─ Pod 2: e-learning-deployment-def456
   └─ Algorithm: Round-robin
                     │
                     ▼
5. Pod serves request
   ├─ Container: Nginx
   ├─ Port: 80
   └─ Content: /usr/share/nginx/html/
                     │
                     ▼
6. Response returns to user
   └─ HTML, CSS, JS, Images
```

### Monitoring Data Flow

```
1. Application Pods
   ├─ Expose metrics endpoint
   └─ Port: /metrics
         │
         ▼
2. Prometheus (Scraper)
   ├─ Scrapes metrics every 30s
   ├─ Stores in time-series DB
   └─ Retention: 7 days
         │
         ▼
3. Grafana (Visualizer)
   ├─ Queries Prometheus
   ├─ Renders dashboards
   └─ Updates every 5s
         │
         ▼
4. User views dashboard
   └─ http://<NODE_IP>:30030
```

## 🧩 Component Details

### 1. AWS Infrastructure Layer

**EC2 Instances:**
- **Type:** t2.medium (2 vCPU, 4GB RAM)
- **OS:** Ubuntu 22.04 LTS
- **Storage:** 8GB gp3 EBS
- **Network:** VPC with public subnet
- **Cost:** ~$0.05/hour per instance

**Security Group:**
```
Inbound Rules:
├─ SSH (22)              → Management access
├─ HTTP (80)             → Web traffic
├─ HTTPS (443)           → Secure web traffic
├─ K8s API (6443)        → Cluster communication
├─ Kubelet (10250)       → Node communication
├─ NodePort (30000-32767)→ Service exposure
├─ Prometheus (9090)     → Monitoring UI
└─ Grafana (3000)        → Dashboard UI

Outbound Rules:
└─ All traffic allowed   → Internet access
```

### 2. Container Runtime Layer

**Docker:**
- **Version:** 24.x
- **Purpose:** Build and run containers
- **Components:**
  - Docker Engine (daemon)
  - Docker CLI (client)
  - containerd (runtime)

**Containerd:**
- **Purpose:** Container runtime for Kubernetes
- **Configuration:** SystemdCgroup enabled
- **Socket:** /run/containerd/containerd.sock

### 3. Kubernetes Control Plane (Master Node)

**API Server (kube-apiserver):**
- **Port:** 6443
- **Purpose:** REST API for all cluster operations
- **Authentication:** Certificate-based
- **Authorization:** RBAC

**Scheduler (kube-scheduler):**
- **Port:** 10251
- **Purpose:** Assigns pods to nodes
- **Algorithm:** Resource-based scheduling

**Controller Manager (kube-controller-manager):**
- **Port:** 10252
- **Purpose:** Runs controller loops
- **Controllers:**
  - Node Controller
  - Replication Controller
  - Endpoints Controller
  - Service Account Controller

**etcd:**
- **Port:** 2379-2380
- **Purpose:** Distributed key-value store
- **Data:** Cluster state and configuration

**Kubelet:**
- **Port:** 10250
- **Purpose:** Node agent
- **Functions:**
  - Manages pods
  - Reports node status
  - Executes health checks

**Kube-proxy:**
- **Purpose:** Network proxy
- **Mode:** iptables
- **Function:** Service load balancing

### 4. Kubernetes Worker Plane (Worker Node)

**Kubelet:**
- Receives pod specs from API server
- Ensures containers are running
- Reports pod status

**Kube-proxy:**
- Maintains network rules
- Enables service communication
- Load balances traffic

**Container Runtime (containerd):**
- Pulls images
- Runs containers
- Manages container lifecycle

### 5. Network Layer

**CNI Plugin (Flannel):**
- **Purpose:** Pod networking
- **CIDR:** 10.244.0.0/16
- **Backend:** VXLAN
- **Function:** Enables pod-to-pod communication

**Service Network:**
- **CIDR:** 10.96.0.0/12
- **Type:** Virtual IPs
- **DNS:** CoreDNS

**Network Flow:**
```
Pod → CNI Bridge → Flannel → Node Network → Internet
```

### 6. Application Layer

**E-Learning Deployment:**
```yaml
Replicas: 2
Strategy: RollingUpdate
Image: yourusername/e-learning:v1
Resources:
  Requests:
    CPU: 100m
    Memory: 128Mi
  Limits:
    CPU: 200m
    Memory: 256Mi
Health Checks:
  Liveness: HTTP GET / (port 80)
  Readiness: HTTP GET / (port 80)
```

**E-Learning Service:**
```yaml
Type: NodePort
Port: 80 (cluster-internal)
TargetPort: 80 (container)
NodePort: 30080 (external)
Selector: app=e-learning
```

**Container Specification:**
```
Base Image: nginx:alpine
Working Dir: /usr/share/nginx/html
Files: HTML, CSS, JS, Images
Port: 80
Process: nginx (daemon off)
```

### 7. Monitoring Layer

**Prometheus Stack:**
```
Components:
├─ Prometheus Server
│  ├─ Port: 9090
│  ├─ Storage: 10Gi
│  ├─ Retention: 7 days
│  └─ Scrape Interval: 30s
│
├─ Grafana
│  ├─ Port: 3000
│  ├─ Storage: 5Gi
│  └─ Dashboards: Pre-configured
│
├─ Alertmanager
│  ├─ Port: 9093
│  └─ Routes: Configured
│
├─ Node Exporter
│  ├─ Port: 9100
│  └─ Metrics: Node-level
│
└─ Kube State Metrics
   ├─ Port: 8080
   └─ Metrics: K8s objects
```

**Metrics Collected:**
```
Node Metrics:
├─ CPU usage
├─ Memory usage
├─ Disk I/O
├─ Network traffic
└─ System load

Pod Metrics:
├─ CPU usage
├─ Memory usage
├─ Network I/O
├─ Restart count
└─ Status

Cluster Metrics:
├─ Node count
├─ Pod count
├─ Deployment status
├─ Service endpoints
└─ Resource quotas
```

## 🔐 Security Architecture

### Authentication & Authorization

**Cluster Access:**
```
User → kubectl → kubeconfig → API Server
                    │
                    ├─ Certificate Authentication
                    ├─ RBAC Authorization
                    └─ Admission Controllers
```

**Service Accounts:**
- Default service account per namespace
- Token-based authentication
- RBAC policies applied

### Network Security

**Security Layers:**
```
1. AWS Security Group (Firewall)
   └─ Controls inbound/outbound traffic

2. Kubernetes Network Policies
   └─ Controls pod-to-pod traffic

3. Service Mesh (Optional)
   └─ mTLS between services
```

### Secrets Management

**Current:**
- Kubernetes Secrets (base64 encoded)
- Grafana admin password in Secret

**Production Recommendations:**
- AWS Secrets Manager
- HashiCorp Vault
- Sealed Secrets

## 📈 Scalability Architecture

### Horizontal Scaling

**Pod Scaling:**
```bash
# Manual scaling
kubectl scale deployment e-learning-deployment --replicas=10

# Auto-scaling (HPA)
kubectl autoscale deployment e-learning-deployment \
  --cpu-percent=70 \
  --min=2 \
  --max=10
```

**Node Scaling:**
```
Current: 1 Master + 1 Worker
Scale to: 1 Master + N Workers

Add worker:
1. Launch new EC2 instance
2. Install Docker + Kubernetes
3. Run kubeadm join command
4. Pods automatically distributed
```

### Vertical Scaling

**Resource Limits:**
```yaml
# Increase pod resources
resources:
  requests:
    cpu: 500m      # from 100m
    memory: 512Mi  # from 128Mi
  limits:
    cpu: 1000m     # from 200m
    memory: 1Gi    # from 256Mi
```

**Instance Sizing:**
```
t2.medium  → t2.large  → t2.xlarge
2 vCPU, 4GB  4 vCPU, 8GB  4 vCPU, 16GB
```

## 🔄 High Availability Architecture

### Current Setup (Single Point of Failure)

```
Master Node (1) → If fails, cluster management stops
Worker Node (1) → If fails, application stops
```

### Production HA Setup

```
┌─────────────────────────────────────────┐
│         Load Balancer (ELB)             │
└────────┬────────────┬───────────────────┘
         │            │
    ┌────▼───┐   ┌───▼────┐   ┌──────────┐
    │Master 1│   │Master 2│   │Master 3  │
    │(Active)│   │(Standby│   │(Standby) │
    └────┬───┘   └───┬────┘   └────┬─────┘
         │           │             │
         └───────────┴─────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
    ┌────▼────┐  ┌────▼────┐  ┌─▼───────┐
    │Worker 1 │  │Worker 2 │  │Worker N │
    └─────────┘  └─────────┘  └─────────┘
```

**HA Components:**
- 3+ Master nodes (odd number)
- etcd cluster (distributed)
- Load balancer for API server
- Multiple worker nodes
- Pod anti-affinity rules

## 🚀 Deployment Pipeline

### Current Manual Process

```
1. Developer commits code
   └─ GitHub repository

2. Build Docker image
   └─ docker build -t image:tag .

3. Push to registry
   └─ docker push image:tag

4. Update Kubernetes
   └─ kubectl set image deployment/app container=image:tag

5. Verify deployment
   └─ kubectl rollout status deployment/app
```

### Production CI/CD Pipeline

```
1. Developer pushes code
   └─ GitHub repository
         │
         ▼
2. GitHub Actions triggered
   ├─ Run tests
   ├─ Build Docker image
   ├─ Scan for vulnerabilities
   └─ Push to registry
         │
         ▼
3. ArgoCD detects change
   ├─ Pulls new image
   ├─ Updates Kubernetes
   └─ Monitors rollout
         │
         ▼
4. Prometheus alerts
   └─ Notify if issues
```

## 📊 Resource Allocation

### Current Resource Usage

**Master Node (t2.medium):**
```
Total: 2 vCPU, 4GB RAM

System Pods:
├─ kube-apiserver:     200m CPU, 512Mi RAM
├─ kube-scheduler:     100m CPU, 256Mi RAM
├─ kube-controller:    200m CPU, 512Mi RAM
├─ etcd:               100m CPU, 512Mi RAM
├─ CoreDNS:            100m CPU, 256Mi RAM
└─ Flannel:            100m CPU, 256Mi RAM
Total System:          800m CPU, 2.3Gi RAM

Monitoring Pods:
├─ Prometheus:         250m CPU, 512Mi RAM
├─ Grafana:            100m CPU, 256Mi RAM
└─ Alertmanager:       50m CPU, 128Mi RAM
Total Monitoring:      400m CPU, 896Mi RAM

Available:             800m CPU, 804Mi RAM
```

**Worker Node (t2.medium):**
```
Total: 2 vCPU, 4GB RAM

System Pods:
├─ kubelet:            100m CPU, 256Mi RAM
├─ kube-proxy:         100m CPU, 128Mi RAM
├─ Flannel:            100m CPU, 256Mi RAM
└─ Node Exporter:      50m CPU, 128Mi RAM
Total System:          350m CPU, 768Mi RAM

Application Pods:
├─ E-Learning Pod 1:   100m CPU, 128Mi RAM
└─ E-Learning Pod 2:   100m CPU, 128Mi RAM
Total Apps:            200m CPU, 256Mi RAM

Available:             1450m CPU, 2.9Gi RAM
```

## 🔍 Observability Stack

### Three Pillars

**1. Metrics (Prometheus)**
```
What: Numerical measurements over time
Examples:
├─ CPU usage: 45%
├─ Memory usage: 2.1GB
├─ Request rate: 100 req/s
└─ Error rate: 0.5%

Storage: Time-series database
Retention: 7 days
Query Language: PromQL
```

**2. Logs (Future: ELK/Loki)**
```
What: Event records
Examples:
├─ Application logs
├─ Error messages
├─ Access logs
└─ Audit logs

Current: kubectl logs
Production: Elasticsearch + Kibana
```

**3. Traces (Future: Jaeger)**
```
What: Request journey through system
Examples:
├─ User request → Service A → Service B → Database
└─ Latency at each step

Current: Not implemented
Production: Jaeger or Zipkin
```

## 🎯 Design Decisions

### Why Kubernetes?

**Alternatives Considered:**
1. **Docker Compose:** Simple but single-host only
2. **Docker Swarm:** Easier but less features
3. **Kubernetes:** Complex but industry standard

**Kubernetes Chosen Because:**
- Industry standard (most jobs require it)
- Rich ecosystem (Helm, Operators, etc.)
- Strong community support
- Cloud-agnostic
- Production-ready features

### Why NodePort?

**Alternatives:**
1. **ClusterIP:** Internal only (not accessible externally)
2. **NodePort:** Simple, works everywhere ✓
3. **LoadBalancer:** Requires cloud provider, costs money
4. **Ingress:** More complex, requires Ingress controller

**NodePort Chosen Because:**
- Simple to understand
- Works on any Kubernetes cluster
- No additional cost
- Good for learning/demo

**Production Would Use:**
- Ingress + cert-manager (HTTPS)
- AWS ALB/NLB (managed load balancer)

### Why Flannel?

**Alternatives:**
1. **Flannel:** Simple, works well ✓
2. **Calico:** More features (network policies)
3. **Weave:** Easy but slower
4. **Cilium:** Advanced (eBPF) but complex

**Flannel Chosen Because:**
- Easy to install
- Reliable
- Good performance
- Sufficient for this use case

### Why Helm for Monitoring?

**Alternatives:**
1. **Manual YAML:** Too many files
2. **Helm:** Package manager, easy ✓
3. **Operators:** More complex

**Helm Chosen Because:**
- One command installation
- Pre-configured stack
- Easy to upgrade
- Community maintained

## 📚 Technology Stack Summary

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Cloud | AWS EC2 | Virtual servers |
| OS | Ubuntu 22.04 | Operating system |
| Container Runtime | Docker + containerd | Run containers |
| Orchestration | Kubernetes 1.28 | Manage containers |
| Network | Flannel | Pod networking |
| Package Manager | Helm | Install apps |
| Application | Nginx | Web server |
| Monitoring | Prometheus | Metrics collection |
| Visualization | Grafana | Dashboards |
| Alerting | Alertmanager | Notifications |
| Registry | Docker Hub | Image storage |
| Version Control | Git/GitHub | Code management |

## 🔮 Future Enhancements

### Phase 1: Security
- [ ] Enable HTTPS (Ingress + cert-manager)
- [ ] Implement Network Policies
- [ ] Add Secrets encryption
- [ ] Enable Pod Security Policies

### Phase 2: Observability
- [ ] Add centralized logging (ELK/Loki)
- [ ] Implement distributed tracing (Jaeger)
- [ ] Configure alerting rules
- [ ] Add custom dashboards

### Phase 3: Automation
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] GitOps (ArgoCD/Flux)
- [ ] Auto-scaling (HPA/VPA)
- [ ] Automated backups (Velero)

### Phase 4: Reliability
- [ ] Multi-master setup
- [ ] Multi-region deployment
- [ ] Disaster recovery plan
- [ ] Chaos engineering tests

### Phase 5: Performance
- [ ] CDN integration (CloudFront)
- [ ] Database caching (Redis)
- [ ] Image optimization
- [ ] Load testing

---

**This architecture represents a production-grade deployment pattern used by companies worldwide. Understanding each component and how they interact is key to becoming a successful DevOps engineer.**
