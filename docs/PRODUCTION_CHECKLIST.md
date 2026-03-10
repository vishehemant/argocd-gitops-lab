# ✅ ArgoCD Production Deployment Checklist

## Pre-Deployment Phase

### Infrastructure & Cluster Setup

- [ ] **Kubernetes Cluster**
  - [ ] HA cluster (3+ master nodes)
  - [ ] etcd backup configured
  - [ ] Network policies defined
  - [ ] Pod security policies/pod security standards enforced
  - [ ] Cluster version is supported (n-2 versions)
  - [ ] CNI plugin installed and tested

- [ ] **Load Balancer & Networking**
  - [ ] Ingress controller installed
  - [ ] SSL/TLS certificates configured
  - [ ] DNS records pointing to load balancer
  - [ ] Network outbound rules allow Git/Docker registry access
  - [ ] Service mesh (optional) configured

- [ ] **Storage**
  - [ ] Persistent volume provisioning configured
  - [ ] Storage classes defined for different tiers
  - [ ] Backup strategy for stateful data implemented

### ArgoCD Installation & Configuration

- [ ] **ArgoCD Installation**
  - [ ] ArgoCD deployed in separate `argocd` namespace
  - [ ] All ArgoCD components deployed (server, repo-server, controller, dex)
  - [ ] ArgoCD version is stable and tested
  - [ ] Replicas set > 1 for HA
  - [ ] Resource limits/requests configured

- [ ] **Access & Authentication**
  - [ ] HTTPS/TLS configured for ArgoCD server
  - [ ] Certificate is valid and from trusted CA
  - [ ] Authentication configured (OAuth2, LDAP, SAML, or local)
  - [ ] Default admin password changed
  - [ ] RBAC roles defined for different teams
  - [ ] API tokens generated for CI/CD automation

- [ ] **Repository Configuration**
  - [ ] Git repository URLs added to ArgoCD
  - [ ] SSH keys/tokens configured for private repos
  - [ ] Read-only credentials used (principle of least privilege)
  - [ ] Repository certificate verification enabled (if private)
  - [ ] Multiple repository servers deployed for redundancy

- [ ] **Storage & Backup**
  - [ ] Persistent storage (PVC) for ArgoCD data
  - [ ] Backup policy for ArgoCD state
  - [ ] Backup tested and verified (RTO/RPO documented)

---

## Application Configuration Phase

### Code Repository Structure

- [ ] **Repository Organization**
  - [ ] Clear structure with `/base` and `/overlays`
  - [ ] Separate paths for dev/staging/prod
  - [ ] Documentation in README.md
  - [ ] `.gitignore` configured
  - [ ] Secrets NOT committed to repo

- [ ] **Manifest Validation**
  - [ ] All YAML files valid (tested with `kubectl --dry-run`)
  - [ ] Image tags are specific (NOT using `latest`)
  - [ ] Resource requests/limits defined
  - [ ] Health probes configured (liveness, readiness)
  - [ ] Security contexts applied

- [ ] **Kustomize/Helm Configuration**
  - [ ] If using Kustomize: overlays tested
  - [ ] If using Helm: values templated properly
  - [ ] Template validation tested
  - [ ] Variable substitution works correctly

### ArgoCD Application Setup

- [ ] **Application Definitions**
  - [ ] Applications created for each logical deployment
  - [ ] Application names follow naming convention
  - [ ] Applications organized in AppProjects by team/environment
  - [ ] Destination namespace matches environment

- [ ] **Sync Policies**
  - [ ] Dev environment: automated sync with self-heal enabled
  - [ ] Staging environment: automated sync without self-heal (for validation)
  - [ ] Production environment: manual sync (controlled promotion)
  - [ ] Prune policy configured appropriately per environment

- [ ] **Access Control**
  - [ ] AppProject created with RBAC boundaries
  - [ ] Teams have access to appropriate projects only
  - [ ] Service accounts for automation configured
  - [ ] Minimum required permissions granted (least privilege)

---

## Security & Compliance Phase

### Secrets Management

- [ ] **Secret Encryption**
  - [ ] NO secrets hardcoded in manifests
  - [ ] Sealed Secrets OR External Secrets Operator configured
  - [ ] Secret rotation policy defined
  - [ ] Secret audit logging enabled

- [ ] **Credentials & Keys**
  - [ ] Git SSH keys stored securely
  - [ ] Docker registry credentials configured
  - [ ] API tokens rotated regularly
  - [ ] Keys are NOT in Git history

### RBAC & Authorization

- [ ] **Kubernetes RBAC**
  - [ ] ServiceAccounts created for each application
  - [ ] ClusterRoles/Roles with minimal permissions
  - [ ] RoleBindings/ClusterRoleBindings configured
  - [ ] No cluster-admin usage in applications

- [ ] **ArgoCD RBAC**
  - [ ] User roles defined (read-only, developer, admin)
  - [ ] API access tokens scoped appropriately
  - [ ] AppProjects restrict capabilities per team
  - [ ] Cross-team access denied

### Security Scanning

- [ ] **Image Security**
  - [ ] Container images scanned for vulnerabilities
  - [ ] Non-root containers enforced
  - [ ] Read-only root filesystem where possible
  - [ ] Image pull policy set to IfNotPresent or Always

- [ ] **Network Security**
  - [ ] Network policies deployed
  - [ ] Ingress rules restrict access
  - [ ] Egress rules restrict outbound traffic
  - [ ] Service-to-service communication authorized

### Compliance & Audit

- [ ] **Logging & Auditing**
  - [ ] K8s audit logging enabled
  - [ ] ArgoCD operation logs retained
  - [ ] Git commit history preserved
  - [ ] Change tracking enabled

- [ ] **Compliance Requirements**
  - [ ] Data residency requirements met
  - [ ] Encryption at rest/in-transit enabled
  - [ ] Compliance scanning tools integrated
  - [ ] Documentation for audit trail prepared

---

## Monitoring & Observability Phase

### Prometheus & Metrics

- [ ] **Metrics Collection**
  - [ ] Prometheus deployed (or external monitoring)
  - [ ] ArgoCD metrics scraped
  - [ ] Application metrics collection configured
  - [ ] Cluster metrics (nodes, pods) collected

- [ ] **Key Metrics Monitored**
  - [ ] `argocd_app_sync_total` (sync count)
  - [ ] `argocd_server_requests_total` (API requests)
  - [ ] `argocd_app_reconcile_duration_seconds` (sync duration)
  - [ ] Application health status
  - [ ] Pod resource usage (CPU, memory)

### Logging

- [ ] **Log Aggregation**
  - [ ] ELK/Loki/Splunk configured
  - [ ] ArgoCD logs shipped to centralized logging
  - [ ] Application logs collected
  - [ ] Kernel/system logs available for troubleshooting

- [ ] **Log Retention**
  - [ ] Retention policy defined (e.g., 30 days)
  - [ ] Sensitive data masked/redacted
  - [ ] Log search and analysis tools configured

### Alerting

- [ ] **Alert Rules**
  - [ ] Alert for sync failures: `argocd_app_info{sync_status="OutOfSync"}`
  - [ ] Alert for controller restarts
  - [ ] Alert for repository unreachable
  - [ ] Alert for missing health information

- [ ] **Notification Channels**
  - [ ] Slack/PagerDuty/Email configured
  - [ ] On-call rotation notifications enabled
  - [ ] Alert routing configured per team
  - [ ] Alert severities (critical, warning, info) defined

- [ ] **Alert Testing**
  - [ ] Test alerts are working
  - [ ] Response procedures documented
  - [ ] Team trained on alert response

### Grafana Dashboards

- [ ] **Dashboard Creation**
  - [ ] ArgoCD overview dashboard
  - [ ] Application-specific dashboards
  - [ ] Cluster health dashboard
  - [ ] Team-specific dashboards created

---

## Disaster Recovery Phase

### Backup & Recovery

- [ ] **Backup Strategy**
  - [ ] ArgoCD state backed up daily
  - [ ] Kubernetes etcd backups automated
  - [ ] ConfigMaps/Secrets backed up
  - [ ] Off-cluster backup storage configured
  - [ ] Backup retention policy enforced

- [ ] **Recovery Testing**
  - [ ] Backup restoration tested monthly
  - [ ] RTO (Recovery Time Objective) defined
  - [ ] RPO (Recovery Point Objective) defined
  - [ ] Disaster recovery runbook documented

### High Availability

- [ ] **ArgoCD Components**
  - [ ] ArgoCD Server: 3+ replicas
  - [ ] Repository Server: 3+ replicas
  - [ ] Application Controller: 3+ replicas
  - [ ] Dex Server: 2+ replicas

- [ ] **Application Resilience**
  - [ ] Pod disruption budgets defined
  - [ ] Pod anti-affinity rules prevent single point of failure
  - [ ] Resource requests/limits prevent starvation
  - [ ] Health probes ensure automatic recovery

### Cluster Redundancy

- [ ] **Multi-Region/Multi-Cluster**
  - [ ] Applications deployed to multiple clusters
  - [ ] Cross-cluster networking configured
  - [ ] Failover mechanism tested
  - [ ] Data synchronization strategy defined

---

## Operational Excellence Phase

### Documentation

- [ ] **Runbooks & Guides**
  - [ ] ArgoCD deployment guide
  - [ ] On-call runbook for common issues
  - [ ] Troubleshooting guide
  - [ ] Secret rotation procedure
  - [ ] Disaster recovery procedure
  - [ ] Team onboarding guide

- [ ] **Architecture Documentation**
  - [ ] System architecture diagram
  - [ ] Network architecture diagram
  - [ ] GitOps workflow diagram
  - [ ] Decision logs for design choices

### Training & Team Readiness

- [ ] **Team Training**
  - [ ] Team trained on GitOps principles
  - [ ] Team trained on ArgoCD operations
  - [ ] Troubleshooting procedures taught
  - [ ] On-call rotation documented

- [ ] **Knowledge Transfer**
  - [ ] Documentation accessible to team
  - [ ] Internal knowledge base created
  - [ ] Video recordings for common procedures
  - [ ] Regular team retrospectives

### Process & Governance

- [ ] **Git Workflow**
  - [ ] Branch protection rules configured
  - [ ] PR review requirements enforced
  - [ ] Automatic testing on PR creation
  - [ ] CODEOWNERS file defines review responsibility

- [ ] **Change Management**
  - [ ] Change request process defined
  - [ ] Change advisory board schedule
  - [ ] Rollback procedures documented
  - [ ] Change window concept for production

- [ ] **Monitoring & Optimization**
  - [ ] Monthly review of metrics
  - [ ] Cost optimization analysis
  - [ ] Performance baseline established
  - [ ] Bottlenecks identified and addressed

---

## Testing & Validation Phase

### Pre-Deployment Testing

- [ ] **Manifest Testing**
  - [ ] `kubectl --dry-run` validation
  - [ ] Policy validation (using OPA/Kyverno if available)
  - [ ] Schema validation
  - [ ] Security scanning

- [ ] **Functional Testing**
  - [ ] Application deployed to staging
  - [ ] Smoke tests pass
  - [ ] Integration tests pass
  - [ ] Performance tests meet baseline

- [ ] **Rollback Testing**
  - [ ] Rollback procedure tested
  - [ ] Previous version available in Git
  - [ ] Fallback plan documented
  - [ ] Emergency contacts list prepared

### Integration Testing

- [ ] **ArgoCD Integration**
  - [ ] Application syncs successfully
  - [ ] Hooks execute in correct order
  - [ ] Finalizers don't block deletion
  - [ ] Error scenarios handled gracefully

- [ ] **External System Integration**
  - [ ] Git webhook authentication works
  - [ ] Docker registry pull successful
  - [ ] Monitoring scrape endpoints reachable
  - [ ] Logging endpoints accepting data

---

## Go-Live Phase

### Pre-Cutover

- [ ] **Final Checklist Verification**
  - [ ] Team lead signs off on all items
  - [ ] Security review completed
  - [ ] Performance testing passed
  - [ ] Documentation finalized

- [ ] **Communication**
  - [ ] Stakeholders notified
  - [ ] Maintenance window scheduled (if needed)
  - [ ] Communication channel established (Slack channel)
  - [ ] Escalation contacts shared

### Deployment

- [ ] **Production Deployment**
  - [ ] Deploy ArgoCD to production cluster
  - [ ] Verify all components running
  - [ ] Test ArgoCD management capabilities
  - [ ] Initial applications deployed

- [ ] **Validation**
  - [ ] Health checks pass
  - [ ] Applications accessible
  - [ ] Monitoring shows all green
  - [ ] No resource errors

### Post-Deployment

- [ ] **Production Stabilization**
  - [ ] Observe metrics for 24 hours
  - [ ] Check for any alerts or anomalies
  - [ ] Verify auto-healing works
  - [ ] Confirm backup processes running

- [ ] **Knowledge Capture**
  - [ ] Document any issues encountered
  - [ ] Capture lessons learned
  - [ ] Update runbooks based on reality
  - [ ] Schedule post-mortem if needed

---

## Environment-Specific Checklists

### Development Deployment Checklist

- [ ] Namespaces created
- [ ] RBAC permissions granted
- [ ] Auto-sync enabled
- [ ] Self-healing enabled
- [ ] Notifications for failures configured
- [ ] Team has access to UI

### Staging Deployment Checklist

- [ ] Mirror production configuration
- [ ] Manual approval steps documented
- [ ] Load testing performed
- [ ] Chaos testing attempted
- [ ] Security scanning completed
- [ ] Performance baselines established

### Production Deployment Checklist

- [ ] All above items completed
- [ ] Change management approval obtained
- [ ] Rollback plan rehearsed
- [ ] On-call team ready
- [ ] Communication channels active
- [ ] Monitoring dashboards live
- [ ] Disaster recovery plan tested

---

## Quick Reference: High-Risk Areas

⚠️ **Critical Areas Requiring Extra Attention:**

1. **Secret Management**
   - No secrets in Git
   - Encryption enabled
   - Rotation scheduled

2. **RBAC**
   - Least privilege principle
   - Segregation of duties
   - Regular audits

3. **Disaster Recovery**
   - Backup automation
   - Recovery testing
   - Clear RTO/RPO

4. **Multi-Environment Parity**
   - Prod matches staging
   - Staging matches dev
   - Environment variables isolated

5. **Network Security**
   - Network policies enforced
   - All traffic encrypted
   - Ingress properly secured

---

## Sign-Off

- [ ] **Development Team**: Signed off on application manifests
- [ ] **DevOps Team**: Signed off on infrastructure/ArgoCD setup
- [ ] **Security Team**: Signed off on security controls
- [ ] **Operations Team**: Signed off on runbooks and procedures
- [ ] **Management**: Signed off for production deployment

---

**Last Updated**: March 2026  
**Maintained By**: DevOps/Platform Engineering Team
