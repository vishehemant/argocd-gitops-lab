# ArgoCD GitOps Lab

## Overview
This project is a hands-on **ArgoCD GitOps Lab** designed to help you learn and master GitOps fundamentals and ArgoCD for Kubernetes deployments. It demonstrates a complete GitOps workflow by deploying a **Node.js web application** and **Prometheus monitoring stack**, using Argo Rollouts for advanced deployment strategies like canary and blue-green rollouts.

### Learning Objectives
- Understand **GitOps principles**: Declarative infrastructure, version-controlled deployments, and automated syncing.
- Master **ArgoCD basics**: Applications, projects, sync policies, and UI/CLI usage.
- Explore **Argo Rollouts**: Implement canary and blue-green deployment strategies.
- Practice **Kustomize**: Environment-specific customizations (dev/prod).
- Gain experience with **monitoring**: Prometheus metrics and Grafana dashboards.
- Learn **rollback and troubleshooting**: Automated scripts and manual recovery.

### Key Features
- **GitOps Workflow**: All changes are version-controlled in Git; ArgoCD syncs them to Kubernetes.
- **Production-Ready Manifests**: Includes security contexts, resource limits, health probes, and best practices.
- **Multi-Environment Support**: Kustomize overlays for dev and prod environments.
- **Monitoring Integration**: Prometheus scrapes metrics; Grafana provides dashboards.
- **Automation Scripts**: Deploy and rollback scripts for quick testing.

## Prerequisites
Before starting, ensure you have:
- **Kubernetes Cluster**: Local (e.g., Minikube, Kind) or cloud (EKS, GKE).
- **kubectl**: Installed and configured to access your cluster.
- **ArgoCD**: Install via `kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`.
- **Argo Rollouts**: Install via `kubectl create namespace argo-rollouts && kubectl apply -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml`.
- **Git**: For cloning and pushing changes.
- **Optional**: Docker (for building custom images), Helm (for advanced installs).

## Project Structure
```
argocd-gitops-lab/
├── apps/                          # Application manifests
│   ├── nginx/                     # Node.js app (folder kept as 'nginx' for path compatibility)
│   │   ├── deployment.yaml        # Kubernetes Deployment with Node.js (port 3000)
│   │   ├── service.yaml           # Kubernetes Service
│   │   └── rollout.yaml           # Argo Rollouts configuration
│   └── prometheus/                # Monitoring stack
│       ├── deployment.yaml
│       ├── service.yaml
│       └── configmap.yaml
├── argocd/                        # ArgoCD configurations
│   ├── applications/
│   │   ├── nginx-app.yaml         # ArgoCD app for Node.js (renamed internally)
│   │   └── prometheus-app.yaml    # ArgoCD app for Prometheus
│   └── projects/
│       └── default-project.yaml   # ArgoCD project settings
├── rollouts/                      # Advanced deployment strategies
│   ├── canary-rollout.yaml        # Canary deployment for Node.js
│   └── blue-green-rollout.yaml    # Blue-green deployment for Node.js
├── monitoring/                    # Monitoring configs
│   ├── prometheus/
│   │   ├── prometheus.yaml
│   │   └── rules.yaml
│   └── grafana/
│       ├── dashboard.yaml
│       └── datasource.yaml
├── scripts/                       # Automation scripts
│   ├── deploy.sh                  # Deploy all apps
│   └── rollback.sh                # Rollback Node.js app
├── kustomize/                     # Environment customizations
│   ├── base/                      # Base manifests
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── overlays/
│       ├── dev/kustomization.yaml # Dev environment tweaks
│       └── prod/kustomization.yaml # Prod environment tweaks
├── argocd-config.yaml             # ArgoCD global config
├── README.md                      # This file
└── .gitignore                     # Git ignore rules
```

## Quick Start Guide
Follow these steps to deploy and learn:

### 1. Clone and Setup
```bash
git clone <your-repo-url>
cd argocd-gitops-lab
```

### 2. Install ArgoCD and Argo Rollouts
```bash
# ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Argo Rollouts
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml
kubectl apply -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/dashboard-install.yaml  # Optional dashboard
```

### 3. Access ArgoCD UI
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open http://localhost:8080
# Login: admin / password from: kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d
```

### 4. Deploy Applications
- **Via Scripts**: Run `./scripts/deploy.sh` to deploy Node.js and Prometheus.
- **Via ArgoCD**: In UI, create Applications using `argocd/applications/*.yaml` as templates. Set repo URL to your Git repo.
- **Manual**: `kubectl apply -f apps/nginx/` for Node.js, `apps/prometheus/` for monitoring.

### 5. Test Deployments
- **Node.js App**: Access via `kubectl port-forward svc/nodejs-demo 3000:3000` → http://localhost:3000
- **Prometheus**: Port-forward to 9090 → http://localhost:9090
- **Argo Rollouts Dashboard**: `kubectl port-forward svc/argo-rollouts-dashboard -n argo-rollouts 3100:3100` → http://localhost:3100

### 6. Experiment with Rollouts
- **Canary**: Update `apps/nginx/deployment.yaml` image to `node:19-alpine`, push to Git. ArgoCD syncs; monitor rollout in Argo Rollouts dashboard.
- **Blue-Green**: Use `rollouts/blue-green-rollout.yaml` for zero-downtime switches.

### 7. Use Kustomize
- Deploy dev: `kubectl apply -k kustomize/overlays/dev/`
- Prod: `kubectl apply -k kustomize/overlays/prod/`

## Usage Examples
- **Sync App**: In ArgoCD UI, select app → Sync.
- **Monitor Health**: Check app status, logs, and metrics in Prometheus.
- **Rollback**: Run `./scripts/rollback.sh` or use ArgoCD UI.
- **Custom Changes**: Edit manifests in Git, commit/push, watch ArgoCD auto-sync.

## Troubleshooting
- **Sync Issues**: Check ArgoCD logs: `kubectl logs -n argocd deployment/argocd-repo-server`.
- **Rollout Stuck**: Use `kubectl argo rollouts abort <rollout-name>` or promote manually.
- **Permissions**: Ensure ArgoCD has access to namespaces.
- **Common Errors**: Invalid YAML, resource conflicts—validate with `kubectl apply --dry-run=client -f <file>`.

## Best Practices Learned
- **Security**: Use non-root containers, RBAC, and secrets management.
- **Scalability**: Resource limits, anti-affinity for HA.
- **CI/CD Integration**: Automate Git pushes via pipelines.
- **Multi-Cluster**: Extend to multiple clusters with ArgoCD.

## Contributing
- Fork, make changes, submit PRs.
- Test in a dev cluster before prod.

## Resources
- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [Argo Rollouts Docs](https://argo-rollouts.readthedocs.io/)
- [GitOps Guide](https://www.gitops.tech/)
- [Kubernetes Docs](https://kubernetes.io/docs/)

This lab provides a complete, runnable environment for mastering ArgoCD and GitOps. Start with basic deployments, then explore rollouts and monitoring. Happy learning!