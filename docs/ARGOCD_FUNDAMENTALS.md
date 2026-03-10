# 📚 ArgoCD Fundamentals & Learning Guide

## Table of Contents
1. [Core Concepts](#core-concepts)
2. [Installation & Setup](#installation--setup)
3. [Basic Operations](#basic-operations)
4. [Advanced Concepts](#advanced-concepts)
5. [Best Practices](#best-practices)
6. [Troubleshooting](#troubleshooting)
7. [Real-World Scenarios](#real-world-scenarios)

---

## Core Concepts

### What is ArgoCD?

**ArgoCD** is a declarative, GitOps continuous delivery tool for Kubernetes. It continuously monitors your Git repository and applies changes automatically to your Kubernetes cluster.

#### Key Principles:
- **Declarative**: Define desired state in Git
- **Version-Controlled**: All changes tracked in Git history
- **Automated**: CD pipeline is automated end-to-end
- **Auditable**: Full audit trail via Git commits
- **Self-Healing**: Auto-syncs if cluster diverges from Git

### GitOps Workflow

```
┌─────────────┐
│ Developer   │
│ Commits     │ ──┐
└─────────────┘   │
                  ├──> Git Repository (Source of Truth)
┌─────────────┐   │
│ CI Pipeline │ ──┘
└─────────────┘
      │
      ▼
┌──────────────────────────────┐
│      ArgoCD Controller       │
│  (Continuous Monitoring)     │
└──────────────────────────────┘
      │
      ├─> Detects Changes
      ├─> Applies Manifests
      ├─> Reconciles State
      └─> Reports Status
      ▼
┌──────────────────────────────┐
│   Kubernetes Cluster         │
│  (Actual State)              │
└──────────────────────────────┘
```

### Core ArgoCD Objects

#### 1. **Application**
Represents a single Kubernetes application deployment.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default               # ArgoCD Project
  source:
    repoURL: https://github.com/user/repo
    targetRevision: HEAD        # Git branch/tag/commit
    path: apps/myapp            # Path in repo
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp            # Target namespace
  syncPolicy:
    automated:
      prune: true               # Delete resources not in Git
      selfHeal: true            # Auto-sync on changes
```

#### 2. **AppProject**
RBAC and repository restrictions for applications.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: production
  namespace: argocd
spec:
  sourceRepos:
    - 'https://github.com/company/*'  # Allowed repos
  destinations:
    - namespace: 'prod-*'               # Allowed namespaces
      server: https://kubernetes.default.svc
```

#### 3. **ApplicationSet**
Template-based application generation (DRY principle).

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: multi-env-apps
spec:
  generators:
    - list:
        elements:
          - env: dev
            cluster: dev-cluster
          - env: prod
            cluster: prod-cluster
  template:
    metadata:
      name: 'myapp-{{env}}'
    spec:
      source:
        path: 'apps/{{env}}'
      destination:
        name: '{{cluster}}'
```

---

## Installation & Setup

### Prerequisites
- Kubernetes cluster (v1.14+)
- kubectl configured
- Helm 3 (optional but recommended)

### Step 1: Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Step 2: Access ArgoCD UI

```bash
# Port-forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get initial password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Open browser: http://localhost:8080
# Login: admin / <password>
```

### Step 3: Install ArgoCD CLI

```bash
# macOS
brew install argocd

# Linux
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd && sudo mv argocd /usr/local/bin/

# Using argocd CLI
argocd login localhost:8080
argocd account list
```

---

## Basic Operations

### Creating an Application

#### Method 1: Using ArgoCD CLI

```bash
argocd app create nginx-app \
  --repo https://github.com/user/repo \
  --path apps/nginx \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

#### Method 2: Using YAML Manifest

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/user/repo.git
    targetRevision: main
    path: apps/nginx
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Syncing Applications

```bash
# Manual sync
argocd app sync nginx-app

# Sync with dry-run
argocd app sync nginx-app --dry-run

# Sync specific resource
argocd app sync nginx-app --resource apps:Deployment:nginx
```

### Viewing Application Status

```bash
# Get app status
argocd app get nginx-app

# Watch app status
argocd app wait nginx-app

# Get application history
argocd app history nginx-app

# Get detailed info
kubectl get application nginx-app -n argocd -o yaml
```

### Rollback

```bash
# Rollback to previous revision
argocd app rollback nginx-app

# Rollback to specific revision
argocd app rollback nginx-app 1

# Using kubectl
kubectl patch application nginx-app -n argocd \
  -p '{"spec":{"source":{"targetRevision":"v1.0"}}}' \
  --type merge
```

---

## Advanced Concepts

### Sync Waves (Deployment Ordering)

Control the order of resource deployment using sync waves:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  annotations:
    argocd.argoproj.io/sync-wave: "0"  # Deploy first
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Deploy second
---
apiVersion: v1
kind: Service
metadata:
  name: app-service
  annotations:
    argocd.argoproj.io/sync-wave: "2"  # Deploy last
```

### Sync Hooks (Lifecycle Hooks)

Run jobs or commands at specific sync phases:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  generateName: db-migration-
  annotations:
    argocd.argoproj.io/hook: PreSync           # Run before sync
    argocd.argoproj.io/hook-phase: Sync        # Phase
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      containers:
      - name: migration
        image: myapp:latest
        command: ["python", "migrate.py"]
      restartPolicy: Never
```

### Using Kustomize

Structure your overlays for different environments:

```bash
argocd app create nginx-dev \
  --repo https://github.com/user/repo \
  --path kustomize/overlays/dev \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev

argocd app create nginx-prod \
  --repo https://github.com/user/repo \
  --path kustomize/overlays/prod \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace prod
```

### Using Helm

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-helm-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://charts.example.com
    chart: mychart
    targetRevision: 1.0.0
    helm:
      values: |
        replicaCount: 3
        image:
          repository: myapp
          tag: v1.0
  destination:
    server: https://kubernetes.default.svc
    namespace: default
```

### Notifications & Webhooks

Send notifications on sync status:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.slack: |
    token: $slack-token
  trigger.on-sync-failed: |
    - when: app.status.operationState.phase in ['Error', 'Failed']
      oncePer: app.status.operationState.finishedAt
      send: [app-health-degraded]
```

---

## Best Practices

### 1. **Repository Structure**

```
repo/
├── apps/
│   ├── nginx/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   └── postgres/
│       ├── statefulset.yaml
│       └── service.yaml
├── base/
│   └── (base manifests)
├── kustomize/
│   ├── base/
│   └── overlays/
│       ├── dev/
│       └── prod/
└── charts/
    └── (Helm charts)
```

### 2. **Namespace Isolation**

```yaml
# Create separate namespaces per environment
---
apiVersion: v1
kind: Namespace
metadata:
  name: argocd-gitops-dev
  labels:
    environment: development
---
apiVersion: v1
kind: Namespace
metadata:
  name: argocd-gitops-prod
  labels:
    environment: production
```

### 3. **RBAC for Applications**

```yaml
# Create ServiceAccount for each application
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp-sa
  namespace: myapp
---
# Grant minimal permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: myapp-role
  namespace: myapp
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: myapp-rolebinding
  namespace: myapp
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: myapp-role
subjects:
- kind: ServiceAccount
  name: myapp-sa
```

### 4. **GitOps Workflow**

```bash
# Feature branch workflow
git checkout -b feature/add-new-config
# Make changes to manifests
git add .
git commit -m "Add new configuration"
git push origin feature/add-new-config
# Create PR, review, and merge to main
# ArgoCD automatically syncs the change
```

### 5. **Secret Management**

Use external secret management (not in Git):

```bash
# Option 1: Sealed Secrets
# Option 2: ArgoCD + HashiCorp Vault
# Option 3: AWS Secrets Manager
# Option 4: Azure Key Vault

# Example with Sealed Secrets
kubectl create secret generic myapp-secret \
  --from-literal=password=secret123 \
  --dry-run=client -o yaml \
  | kubeseal -f -
```

---

## Troubleshooting

### Application Won't Sync

```bash
# Check application status
argocd app get myapp

# Check detailed status
kubectl get application myapp -n argocd -o yaml

# View sync error
argocd app logs myapp

# Check ArgoCD server logs
kubectl logs -n argocd deployment/argocd-application-controller
```

### Cluster Connection Issues

```bash
# List configured clusters
argocd cluster list

# Get cluster info
kubectl get secret -n argocd -l argocd.argoproj.io/secret-type=cluster -o yaml

# Reconnect cluster
argocd cluster add <context-name>
```

### Resource Stuck in Finalizers

```bash
# Check if resource has finalizers
kubectl get <resource> <name> -o yaml | grep finalizers

# Remove finalizer if stuck
kubectl patch <resource> <name> -p '{"metadata":{"finalizers":null}}'
```

### ArgoCD Can't Delete Resources

```yaml
# Add deletion policy to resources
metadata:
  annotations:
    argocd.argoproj.io/compare-result: "true"
    argocd.argoproj.io/sync-options: "Validate=false"
```

---

## Real-World Scenarios

### Scenario 1: Multi-Environment Deployment

```bash
# Dev environment
argocd app create app-dev \
  --repo https://github.com/company/repo \
  --path kustomize/overlays/dev \
  --dest-namespace app-dev

# Prod environment  
argocd app create app-prod \
  --repo https://github.com/company/repo \
  --path kustomize/overlays/prod \
  --dest-namespace app-prod
```

### Scenario 2: Database Migration Before App Deploy

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migrate
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: myapp:latest
        command: ["python", "manage.py", "migrate"]
      restartPolicy: Never
```

### Scenario 3: Canary Deployment with Argo Rollouts

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: myapp
spec:
  replicas: 3
  strategy:
    canary:
      steps:
      - setWeight: 20    # Route 20% to new version
      - pause:
          duration: 10m  # Wait for manual approval
      - setWeight: 50
      - pause: {}
      - setWeight: 100
```

---

## Key Takeaways

✓ ArgoCD automates GitOps workflows  
✓ Git is the single source of truth  
✓ All changes are auditable and reversible  
✓ Use appropriate sync policies for your needs  
✓ Leverage ApplicationSets for multi-environment deployments  
✓ Implement proper RBAC and secret management  
✓ Monitor and alert on sync failures  
✓ Establish clear GitOps workflows with your team  

---

## Additional Resources

- [Official ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD GitHub Repository](https://github.com/argoproj/argo-cd)
- [Argo Rollouts Documentation](https://argoproj.github.io/argo-rollouts/)
- [GitOps Best Practices](https://www.gitops.tech/)
