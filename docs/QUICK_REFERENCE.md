# 📋 ArgoCD Quick Reference & Cheat Sheet

## Installation Quick Commands

```bash
# Create ArgoCD namespace and install
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for components to start
kubectl wait --for=condition=Ready pod --all -n argocd --timeout=300s

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get default password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Change default password
argocd account update-password
```

---

## ArgoCD CLI Essential Commands

### Basic Operations

```bash
# Login to ArgoCD
argocd login <argocd-server>

# Create application
argocd app create nginx-app \
  --repo https://github.com/user/repo \
  --path apps/nginx \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# List applications
argocd app list

# Get application details
argocd app get <app-name>

# Sync application (apply Git changes to cluster)
argocd app sync <app-name>

# Sync with dry-run (preview changes)
argocd app sync <app-name> --dry-run

# Wait for sync completion
argocd app wait <app-name>

# View application history  
argocd app history <app-name>

# Rollback to previous revision
argocd app rollback <app-name>

# Rollback to specific revision
argocd app rollback <app-name> <revision>

# Delete application
argocd app delete <app-name>
```

### Advanced Commands

```bash
# Sync specific resource only
argocd app sync <app-name> --resource <group>:<kind>:<name>

# Sync with different sync strategy
argocd app sync <app-name> --sync-strategy=apply  # or hook-based

# Get application logs
argocd app logs <app-name>

# Get application diff (Git vs Cluster)
argocd app diff <app-name>

# Update application configuration
argocd app set <app-name> --repo <new-repo>

# Patch application 
argocd app patch <app-name> --type json --json-patch='[...]'

# Refresh application (re-clone repo, re-render manifests)
argocd app wait <app-name> --refresh

# Get application manifest
argocd app get <app-name> -o json | jq '.status.resources'
```

---

## Kubernetes kubectl Commands

### View ArgoCD Status

```bash
# Check ArgoCD server
kubectl get pods -n argocd
kubectl get svc -n argocd

# View application CRs
kubectl get application -n argocd
kubectl describe application <app-name> -n argocd
kubectl get application <app-name> -n argocd -o yaml

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n argocd deployment/argocd-repo-server

# Stream logs
kubectl logs -n argocd -f deployment/argocd-application-controller
```

### Troubleshooting

```bash
# Check if Git repo is accessible
kubectl logs -n argocd deployment/argocd-repo-server | grep "repository"

# Check sync hooks execution
kubectl get pods -n <app-namespace> --sort-by=.metadata.creationTimestamp

# Check resource events
kubectl get events -n argocd --sort-by='.lastTimestamp'

# Debug application sync
kubectl describe application <app-name> -n argocd
kubectl get application <app-name> -n argocd -o jsonpath='{.status.conditions}'

# Check cluster connectivity
kubectl get clusters -n argocd
kubectl get secret -n argocd -l argocd.argoproj.io/secret-type=cluster
```

---

## YAML Manifests Quick Templates

### Basic Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/user/repo.git
    targetRevision: main
    path: apps/myapp
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

### Application with Hooks

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  generateName: db-migrate-
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

### ApplicationSet for Multi-Environment

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
          - env: prod
  template:
    metadata:
      name: 'myapp-{{env}}'
    spec:
      source:
        path: 'apps/overlays/{{env}}'
      destination:
        namespace: 'myapp-{{env}}'
```

### AppProject with RBAC

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: team-project
spec:
  sourceRepos:
    - 'https://github.com/company/repo/*'
  destinations:
    - namespace: 'team-*'
      server: https://kubernetes.default.svc
  clusterResourceWhitelist:
    - group: '*'
      kind: 'Namespace'
  namespaceResourceBlacklist:
    - group: ''
      kind: 'Secret'
```

---

## Sync Policies Explained

### Auto-Sync (Recommended for Dev/Staging)

```yaml
syncPolicy:
  automated:
    prune: true       # Delete resources not in Git
    selfHeal: true    # Re-sync on cluster drift
```

**When to use**: Dev, internal staging
**Risk**: Automatic changes without approval
**Benefit**: Always matches Git

### Manual Sync (Recommended for Production)

```yaml
syncPolicy:
  automated: null  # Disabled - requires manual approval
```

**When to use**: Production, critical systems
**Risk**: Requires manual intervention
**Benefit**: Full control over deployments

### Selective Sync

```yaml
syncPolicy:
  syncOptions:
    - Validate=true
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
```

---

## Common Troubleshooting Scenarios

### Scenario 1: Application Stuck in "Syncing"

```bash
# Check status
argocd app get myapp

# View detailed error
kubectl describe application myapp -n argocd

# Check controller logs
kubectl logs -n argocd deployment/argocd-application-controller | grep myapp

# Force refresh
argocd app wait myapp --refresh

# Manual sync if needed
argocd app sync myapp --force
```

### Scenario 2: Resource Won't Delete (Finalizer Issue)

```bash
# Check finalizers
kubectl get application myapp -n argocd -o yaml | grep -A5 finalizers

# Remove finalizer if stuck
kubectl patch application myapp -n argocd -p '{"metadata":{"finalizers":null}}'

# Alternative: Delete with grace period
kubectl delete application myapp -n argocd --grace-period=0 --force
```

### Scenario 3: Git Repository Unreachable

```bash
# Check repository status
argocd repo list

# Check repository server logs
kubectl logs -n argocd deployment/argocd-repo-server | grep -i "git\|repository"

# Verify Git credentials
kubectl get secret -n argocd -l argocd.argoproj.io/secret-type=repository -o yaml

# Force repository reload
kubectl delete pod -n argocd -l app.kubernetes.io/name=argocd-repo-server
```

### Scenario 4: Application Out of Sync

```bash
# Check what's different
argocd app diff myapp

# Manual sync
argocd app sync myapp

# Sync specific resource
argocd app sync myapp --resource apps:Deployment:myapp

# Update Git and let auto-sync handle it
git pull origin main
git push origin main
```

### Scenario 5: Pod Keeps Restarting

```bash
# Check pod status
kubectl describe pod <pod-name> -n <namespace>

# View pod logs
kubectl logs <pod-name> -n <namespace>

# View previous logs (after crash)
kubectl logs <pod-name> -n <namespace> --previous

# Check resource usage
kubectl top pod <pod-name> -n <namespace>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

---

## Performance Optimization

### Reduce Sync Time

```yaml
# Use SSH instead of HTTPS
repoURL: git@github.com:user/repo.git

# Use lightweight manifests
# Avoid heavy Helm charts or complex Kustomize

# Configure repository cache
server:
  cache:
    repoCacheExpiration: 60m
    
# Use specific path instead of root
path: apps/myapp
```

### Reduce Cluster API Calls

```yaml
# Increase comparison interval
application:
  controller:
    appInstanceLabelKey: "argocd.argoproj.io/instance"
    
# Disable auto-sync if not needed
syncPolicy:
  automated: null
  
# Use less frequent updates
refreshInterval: 5m
```

---

## Security Best Practices

```bash
# 1. Create SSH keys for Git access
ssh-keygen -t rsa -b 4096 -f ~/.ssh/argocd

# 2. Add to Git deploy keys
cat ~/.ssh/argocd.pub  # Add to GitHub/GitLab

# 3. Create Kubernetes secret
kubectl create secret generic git-creds \
  -n argocd \
  --from-file=ssh-privatekey=~/.ssh/argocd

# 4. Create restrictive RBAC
argocd account create ci-user
argocd account update-password --current-password=<password> --new-password=<new-password>

# 5. Rotate credentials regularly
# Schedule rotation of SSH keys every 90 days

# 6. Use read-only Git tokens
# Create PATs with "read:repo" permission only
```

---

## Backup & Disaster Recovery

```bash
# Backup ArgoCD configuration
kubectl get -n argocd all -o yaml > argocd-backup.yaml

# Backup applications
argocd app list -o json > apps-backup.json

# Backup specific application
kubectl get application myapp -n argocd -o yaml > myapp-backup.yaml

# Restore application
kubectl apply -f myapp-backup.yaml

# Backup and restore entire namespace
kubectl get ns argocd -o yaml | kubectl apply -f -
kubectl get all -n argocd -o yaml | kubectl apply -f -
```

---

## Monitoring & Alerts Setup

```bash
# View Prometheus metrics endpoint
kubectl port-forward svc/prometheus -n monitoring 9090:9090

# Query ArgoCD metrics
curl http://localhost:9090/api/v1/query?query=argocd_app_info

# View AlertManager
kubectl port-forward svc/alertmanager -n monitoring 9093:9093

# Check alert status
curl http://localhost:9093/api/v1/alerts
```

---

## Quick Deployment Scripts

### Deploy to Dev

```bash
#!/bin/bash
REPO_URL="https://github.com/user/repo"
APP_NAME="myapp"
NAMESPACE="dev"

argocd app create $APP_NAME-$NAMESPACE \
  --repo $REPO_URL \
  --path apps/$APP_NAME/overlays/$NAMESPACE \
  --dest-namespace $NAMESPACE \
  --sync-policy automated \
  --auto-prune \
  --self-heal

argocd app wait $APP_NAME-$NAMESPACE
echo "Deployment complete!"
```

### Rollback Script

```bash
#!/bin/bash
APP_NAME="$1"
REVISION="${2:-0}"

echo "Rolling back $APP_NAME to revision $REVISION..."
argocd app rollback $APP_NAME $REVISION
argocd app wait $APP_NAME
echo "Rollback complete!"
```

---

## Essential Links

| Topic | Link |
|-------|------|
| ArgoCD Docs | https://argo-cd.readthedocs.io/ |
| Argo Rollouts | https://argoproj.github.io/argo-rollouts/ |
| GitOps Principles | https://www.gitops.tech/ |
| Kustomize Doc | https://kustomize.io/ |
| Helm | https://helm.sh/ |

---

## Pro Tips

✅ **Use Git for everything** - Every configuration in version control  
✅ **Semantic commits** - Clear, meaningful commit messages  
✅ **Branch protection** - Require PRs before merging to main  
✅ **Automate testing** - Test manifests before merge  
✅ **Monitor closely** - Set up alerts for sync failures  
✅ **Document decisions** - Keep runbooks updated  
✅ **Regular drills** - Practice disaster recovery  
✅ **Stay updated** - Monitor ArgoCD releases

---

**Bookmark this page for quick reference! 🔖**
