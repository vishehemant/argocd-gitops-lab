# 🎓 Complete ArgoCD GitOps Learning & Implementation Guide

Welcome! This is a **comprehensive, production-ready ArgoCD GitOps project** designed to help you master GitOps fundamentals and prepare for real-world DeOps/SRE roles.

---

## 📚 What's Included

This repository contains:

### 1. **Hands-On Project** (`apps/`, `argocd/`, `rollouts/`)
- Complete Node.js application deployments
- Prometheus monitoring stack
- Advanced deployment strategies (canary, blue-green)
- Argo Rollouts integration
- Real-world configurations

### 2. **Production-Ready Infrastructure**
- RBAC (Role-Based Access Control) configurations
- ServiceAccount setup for applications
- Separate namespaces for dev/prod
- Network policies and security contexts
- Resource quotas and limits

### 3. **Comprehensive Documentation**
- **[ARGOCD_FUNDAMENTALS.md](./docs/ARGOCD_FUNDAMENTALS.md)** - Complete learning guide
- **[INTERVIEW_PREP.md](./docs/INTERVIEW_PREP.md)** - Interview preparation with Q&A
- **[PRODUCTION_CHECKLIST.md](./docs/PRODUCTION_CHECKLIST.md)** - Deployment checklist

### 4. **Monitoring & Alerting**
- Prometheus rules and configuration
- Alert management configuration
- 50+ pre-configured alerts
- Slack/PagerDuty integration

### 5. **Automation Scripts**
- Enhanced `deploy.sh` with error handling
- Advanced `rollback.sh` with validation
- Logging and status monitoring

---

## 🚀 Quick Start (5 Minutes)

### Prerequisites
```bash
# Install required tools
kubectl version --client          # Kubernetes CLI
git --version                     # Version control
curl --version                    # For downloading manifests
```

### Step 1: Install ArgoCD
```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD (latest stable version)
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for all components to start
kubectl wait --for=condition=Ready pod --all -n argocd --timeout=300s

# Port-forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Step 2: Access ArgoCD UI
```bash
# Get initial admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

echo "ArgoCD URL: http://localhost:8080"
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"
```

### Step 3: Deploy Your First Application
```bash
# Clone this repository
git clone https://github.com/user/argocd-gitops-lab.git
cd argocd-gitops-lab

# Run the deployment script (dev environment)
bash scripts/deploy.sh dev all
```

✅ That's it! Your first GitOps deployment is running.

---

## 📖 Learning Path

Follow this structured path to master ArgoCD:

### Phase 1: Fundamentals (1-2 weeks)
1. Read [ARGOCD_FUNDAMENTALS.md](./docs/ARGOCD_FUNDAMENTALS.md)
   - GitOps principles
   - Core ArgoCD concepts
   - Basic operations

2. Practice
   - Deploy the sample application
   - Explore ArgoCD UI
   - Try manual syncs and rollbacks

3. Experiment
   - Modify manifests and watch GitOps workflow
   - Create your own applications
   - Practice with different sync policies

### Phase 2: Advanced Concepts (2-3 weeks)
1. Study
   - Sync waves and hooks
   - ApplicationSets for multi-environment
   - Kustomize and Helm integration
   - RBAC and security

2. Practice Advanced Topics
   - Implement pre/post-sync hooks
   - Deploy with Kustomize overlays
   - Set up multi-environment deployments
   - Configure RBAC rules

3. Build
   - Create your own production setup
   - Implement monitoring and alerting
   - Design disaster recovery

### Phase 3: Production Ready (2-3 weeks)
1. Prepare for Production
   - Follow [PRODUCTION_CHECKLIST.md](./docs/PRODUCTION_CHECKLIST.md)
   - Implement all security controls
   - Set up monitoring and logging
   - Create runbooks and documentation

2. Testing
   - Disaster recovery drills
   - Load testing
   - Security scanning
   - Failover testing

3. Go-Live
   - Deploy to production
   - Monitor and optimize
   - Refine based on real-world usage

### Phase 4: Interview Preparation (1-2 weeks)
1. Review [INTERVIEW_PREP.md](./docs/INTERVIEW_PREP.md)
   - Common interview questions
   - Design questions
   - Hands-on exercises

2. Practice
   - Answer sample questions
   - Do hands-on exercises
   - Discuss scenarios with peers

---

## 📁 Project Structure Explained

```
argocd-gitops-lab/
│
├── 📄 README.md                    ← You are here
├── 📄 azure-pipelines.yml          # CI/CD pipeline configuration
├── 📄 argocd-config.yaml           # ArgoCD global configuration
│
├── 📂 apps/                        # Application manifests
│   ├── nginx/                      # Node.js app (legacy naming)
│   │   ├── deployment.yaml        # Pod specification
│   │   ├── service.yaml           # Service definition
│   │   └── rollout.yaml           # Argo Rollouts configuration
│   └── prometheus/                # Monitoring stack
│       ├── deployment.yaml
│       ├── service.yaml
│       └── configmap.yaml
│
├── 📂 argocd/                      # ArgoCD configurations
│   ├── applications/
│   │   ├── nginx-app.yaml         # ArgoCD Application CR
│   │   └── prometheus-app.yaml
│   └── projects/
│       └── default-project.yaml   # RBAC project
│
├── 📂 rbac/                        # ⭐ NEW: RBAC configurations
│   ├── service-accounts.yaml      # ServiceAccounts for apps
│   ├── cluster-roles.yaml         # ClusterRole definitions
│   └── role-bindings.yaml         # RBAC bindings
│
├── 📂 namespaces/                  # ⭐ NEW: Namespace definitions
│   ├── dev-namespace.yaml         # Dev environment namespace
│   └── prod-namespace.yaml        # Prod environment namespace
│
├── 📂 kustomize/                   # Kustomize overlays
│   ├── base/                      # Base manifests
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── overlays/
│       ├── dev/                   # Dev customizations
│       │   └── kustomization.yaml
│       └── prod/                  # Prod customizations
│           └── kustomization.yaml
│
├── 📂 rollouts/                    # Advanced deployment strategies
│   ├── canary-rollout.yaml        # Canary strategy (20%→100%)
│   └── blue-green-rollout.yaml    # Blue-green strategy
│
├── 📂 monitoring/                  # ⭐ ENHANCED: Monitoring configs
│   ├── prometheus-rules.yaml      # 50+ alert rules
│   ├── prometheus-config.yaml     # Prometheus scrape configs
│   ├── alertmanager-config.yaml   # Alert routing
│   ├── grafana/
│   │   ├── dashboard.yaml
│   │   └── datasource.yaml
│   └── prometheus/
│       ├── prometheus.yaml
│       └── rules.yaml
│
├── 📂 vault/                       # Secret management
│   └── vault-agent-config.yaml
│
├── 📂 scripts/                     # ⭐ ENHANCED: Automation
│   ├── deploy.sh                  # Production-ready deploy script
│   └── rollback.sh                # Production-ready rollback
│
└── 📂 docs/                        # ⭐ NEW: Comprehensive documentation
    ├── ARGOCD_FUNDAMENTALS.md     # Complete learning guide
    ├── INTERVIEW_PREP.md          # Interview preparation
    └── PRODUCTION_CHECKLIST.md    # Pre-deployment checklist
```

**⭐ NEW** = Files/folders added in this enhanced version

---

## 🔑 Key Concepts You'll Learn

### 1. **GitOps Workflow**
```
Code Repo → Git Commit → ArgoCD Detects → Compares States → Auto-Syncs → Deployed
    ↑                                                                          ↓
    └──────────────────── Git as Source of Truth ───────────────────────────┘
```

### 2. **Declarative vs Imperative**
```
❌ Imperative (Traditional CI/CD)
kubectl run myapp --image=myapp:v1
kubectl set image deployment/myapp image=myapp:v2

✅ Declarative (GitOps with ArgoCD)
# In Git: deployment.yaml specifies desired state
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  template:
    spec:
      containers:
      - image: myapp:v2  # Just change version in Git → ArgoCD handles rest
```

### 3. **Self-Healing**
- User accidentally deletes pod: `kubectl delete pod myapp-xyz`
- ArgoCD detects cluster diverged from Git
- ArgoCD restarts the pod automatically
- No manual intervention needed!

### 4. **Audit Trail**
Every deployment captured in Git:
```bash
git log --oneline
# a1b2c3d Update nginx replicas from 2 to 3
# d4e5f6g Roll back prometheus to v2.1.0
# h7i8j9k Increase resource limits in prod
# ... full history!
```

---

## 🛡️ Security Features in This Project

✅ **RBAC Implementation**
- ServiceAccounts with minimal permissions
- ClusterRoles and Roles for different functions
- RoleBindings restrict access per namespace

✅ **Secrets Management**
- No secrets in Git (ever!)
- Integration with HashiCorp Vault
- Support for Sealed Secrets

✅ **Network Policies**
- Pod-to-pod communication restricted
- Egress rules limit outbound traffic
- Ingress properly controlled

✅ **Pod Security**
- Non-root containers
- Resource limits/requests
- Read-only root filesystem option
- Container security contexts

✅ **Compliance & Audit**
- All changes tracked in Git
- Kubernetes audit logging
- 50+ monitoring alerts
- Slack/PagerDuty notifications

---

## 📊 Monitoring & Alerting

This project includes **production-grade monitoring**:

### Pre-configured Alerts
- ✅ Application sync failures
- ✅ ArgoCD component down
- ✅ Repository unreachable
- ✅ Sync performance degradation
- ✅ Resource utilization warnings
- ✅ Kubernetes node issues
- ✅ Pod restart storms
- ... and 42 more!

### Quick Alert Setup
```bash
# Deploy Prometheus
kubectl apply -f monitoring/prometheus-config.yaml

# Deploy Alert Rules
kubectl apply -f monitoring/prometheus-rules.yaml

# Deploy AlertManager
kubectl apply -f monitoring/alertmanager-config.yaml
```

---

## 🚀 Advanced Features

### Canary Deployments
Deploy new version gradually (20% → 50% → 100%) with automatic rollback:
```bash
# Automatic traffic shift with monitoring
kubectl apply -f rollouts/canary-rollout.yaml
```

### Blue-Green Deployments
Maintain two full environments, switch instantly:
```bash
# Zero-downtime deployment
kubectl apply -f rollouts/blue-green-rollout.yaml
```

### Multi-Environment Setup
Different configurations for dev/staging/prod:
```bash
# Dev: 1 replica, less resources
kubectl apply -f kustomize/overlays/dev/

# Prod: 5 replicas, strict limits
kubectl apply -f kustomize/overlays/prod/
```

### RBAC per Team
Team A can only access their apps:
```yaml
AppProject: "team-a"
  sourceRepos: ["github.com/company/team-a/*"]
  destinations: ["team-a-*"]
```

---

## 💡 Real-World Scenarios

### Scenario 1: Developer Made a Bad Deployment 😱
**Problem**: Dev pushed bad image, production down
```bash
# Solution: One command to rollback
./scripts/rollback.sh prod nodejs-app
# ArgoCD syncs to previous stable version immediately
```

### Scenario 2: Need to Change Configuration 🔧
**Problem**: Need to increase replicas in prod
```bash
# Solution: Just update Git
# deployment.yaml: replicas: 3 → replicas: 5
git commit -m "Increase prod replicas to 5"
git push origin main
# ArgoCD auto-syncs within 30 seconds!
```

### Scenario 3: Disaster Recovery 🚨
**Problem**: Entire cluster corrupted, need to restore
```bash
# Solution: Redeploy from Git
# Create new cluster, point ArgoCD at same Git repo
# All applications, configurations re-deployed in minutes!
```

---

## 📈 What You'll Be Able to Do

After completing this course, you can:

✅ **Design & Implement**
- Architect GitOps-based deployment systems
- Design multi-environment setups
- Implement RBAC and security policies

✅ **Deploy & Manage**
- Deploy applications using ArgoCD
- Manage advanced deployment strategies
- Handle multi-cluster deployments

✅ **Monitor & Troubleshoot**
- Monitor ArgoCD and applications
- Set up alerting and notifications
- Troubleshoot sync failures and cluster issues

✅ **Interview Ready**
- Answer ArgoCD technical questions
- Design systems with GitOps
- Handle production scenarios
- Discuss trade-offs and best practices

---

## 🔗 Quick Commands Reference

```bash
# ============ ArgoCD Operations ============
argocd login localhost:8080
argocd app list
argocd app get myapp
argocd app sync myapp
argocd app wait myapp
argocd app rollback myapp 0
argocd app delete myapp

# ============ Deployment ============
bash scripts/deploy.sh dev all      # Deploy to dev
bash scripts/deploy.sh prod all     # Deploy to prod

# ============ Rollback ============
bash scripts/rollback.sh dev nodejs-app
bash scripts/rollback.sh prod nodejs-app

# ============ Monitoring ============
kubectl get pods -n argocd
kubectl logs -n argocd deployment/argocd-application-controller
kubectl get application -n argocd

# ============ Git History ============
git log --oneline
git show <commit>
git revert <commit>  # Rollback via Git
```

---

## 📚 Documentation Map

| Document | Purpose | Time |
|----------|---------|------|
| **[ARGOCD_FUNDAMENTALS.md](./docs/ARGOCD_FUNDAMENTALS.md)** | Learn ArgoCD concepts | 3-4 hours |
| **[INTERVIEW_PREP.md](./docs/INTERVIEW_PREP.md)** | Interview Q&A | 2-3 hours |
| **[PRODUCTION_CHECKLIST.md](./docs/PRODUCTION_CHECKLIST.md)** | Pre-deployment review | 30 min check |
| **This README** | Overview & quick start | 15 min |

---

## 🎯 Learning Milestones

- [ ] ✅ Understand GitOps principles
- [ ] ✅ Install and access ArgoCD
- [ ] ✅ Deploy first application
- [ ] ✅ Perform manual sync
- [ ] ✅ Rollback a deployment
- [ ] ✅ Set up RBAC rules
- [ ] ✅ Configure monitoring
- [ ] ✅ Design multi-environment setup
- [ ] ✅ Implement canary deployment
- [ ] ✅ Pass interview questions
- [ ] ✅ Deploy to production

---

## 🤝 Contributing

Found an issue or want to improve the project?

```bash
# Create a branch
git checkout -b feature/improvement

# Make changes
# Commit with clear messages
git commit -m "Add: New feature or fix"

# Push and create PR
git push origin feature/improvement
```

---

## 📞 Support & Resources

- **ArgoCD Docs**: https://argo-cd.readthedocs.io/
- **GitOps Blog**: https://www.gitops.tech/
- **Argo Community**: https://argoproj.github.io/

---

## 📄 License

This project is licensed under MIT License - use freely for learning.

---

## 🎓 Summary

This project will transform you from ArgoCD beginner to production-ready:

1. **Fundamentals**: Complete learning guide with examples
2. **Practice**: Hands-on deployment with real applications
3. **Advanced**: Multi-environment, monitoring, security
4. **Production**: Checklists, best practices, disaster recovery
5. **Interview**: Preparation materials and real-world scenarios

**Time Investment**: ~6-8 weeks for complete mastery  
**Outcome**: Production-grade GitOps expertise

---

**Ready to master GitOps? Start with [ARGOCD_FUNDAMENTALS.md](./docs/ARGOCD_FUNDAMENTALS.md)! 🚀**
