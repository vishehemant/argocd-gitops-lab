#!/bin/bash

################################################################################
# ArgoCD GitOps Lab - Deployment Script
# Purpose: Deploy applications using ArgoCD with error handling and validation
# Usage: ./deploy.sh [dev|prod] [all|nginx|prometheus]
################################################################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${PROJECT_ROOT}/deploy-$(date +%Y%m%d_%H%M%S).log"

# Default values
ENVIRONMENT="${1:-dev}"
DEPLOYMENT_TARGET="${2:-all}"

# Logging function
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "ERROR" "${RED}✗ Error: $1${NC}"
    exit 1
}

success_msg() {
    log "SUCCESS" "${GREEN}✓ $1${NC}"
}

info_msg() {
    log "INFO" "${BLUE}ℹ $1${NC}"
}

warn_msg() {
    log "WARN" "${YELLOW}⚠ $1${NC}"
}

# Validate prerequisites
validate_prerequisites() {
    info_msg "Validating prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        error_exit "kubectl not found. Please install kubectl."
    fi
    success_msg "kubectl found"
    
    # Check git
    if ! command -v git &> /dev/null; then
        error_exit "git not found. Please install git."
    fi
    success_msg "git found"
    
    # Check kubernetes connectivity
    if ! kubectl cluster-info &> /dev/null; then
        error_exit "Cannot connect to Kubernetes cluster. Check kubeconfig."
    fi
    success_msg "Kubernetes cluster accessible"
    
    # Check ArgoCD CLI (optional but recommended)
    if ! command -v argocd &> /dev/null; then
        warn_msg "argocd CLI not found. Some features may be limited."
    else
        success_msg "argocd CLI found"
    fi
}

# Validate environment
validate_environment() {
    info_msg "Validating environment: $ENVIRONMENT"
    
    if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
        error_exit "Invalid environment: $ENVIRONMENT. Use 'dev' or 'prod'."
    fi
    
    # Check if namespace exists or can be created
    local namespace="argocd-gitops-${ENVIRONMENT}"
    if ! kubectl get namespace "$namespace" &> /dev/null; then
        warn_msg "Namespace $namespace does not exist. Will be created."
    else
        success_msg "Namespace $namespace exists"
    fi
}

# Validate deployment target
validate_deployment_target() {
    info_msg "Validating deployment target: $DEPLOYMENT_TARGET"
    
    if [[ ! "$DEPLOYMENT_TARGET" =~ ^(all|nginx|prometheus)$ ]]; then
        error_exit "Invalid target: $DEPLOYMENT_TARGET. Use 'all', 'nginx', or 'prometheus'."
    fi
}

# Create namespaces
create_namespaces() {
    info_msg "Creating namespaces..."
    
    kubectl apply -f "${PROJECT_ROOT}/namespaces/dev-namespace.yaml" 2>/dev/null || \
        warn_msg "Dev namespace may already exist"
    
    kubectl apply -f "${PROJECT_ROOT}/namespaces/prod-namespace.yaml" 2>/dev/null || \
        warn_msg "Prod namespace may already exist"
    
    success_msg "Namespaces ready"
}

# Apply RBAC configurations
apply_rbac() {
    info_msg "Applying RBAC configurations..."
    
    kubectl apply -f "${PROJECT_ROOT}/rbac/service-accounts.yaml" || \
        error_exit "Failed to apply service accounts"
    
    kubectl apply -f "${PROJECT_ROOT}/rbac/cluster-roles.yaml" || \
        error_exit "Failed to apply cluster roles"
    
    kubectl apply -f "${PROJECT_ROOT}/rbac/role-bindings.yaml" || \
        error_exit "Failed to apply role bindings"
    
    success_msg "RBAC configurations applied"
}

# Deploy applications using ArgoCD
deploy_argocd_app() {
    local app_name=$1
    local namespace="argocd-gitops-${ENVIRONMENT}"
    
    info_msg "Deploying $app_name to $ENVIRONMENT environment..."
    
    # Check if ArgoCD is running
    if ! kubectl get namespace argocd &> /dev/null; then
        error_exit "ArgoCD namespace not found. Install ArgoCD first."
    fi
    
    # Apply the ArgoCD application
    local app_manifest=""
    case $app_name in
        nginx)
            app_manifest="${PROJECT_ROOT}/argocd/applications/nginx-app.yaml"
            ;;
        prometheus)
            app_manifest="${PROJECT_ROOT}/argocd/applications/prometheus-app.yaml"
            ;;
        *)
            error_exit "Unknown application: $app_name"
            ;;
    esac
    
    if [[ ! -f "$app_manifest" ]]; then
        error_exit "Application manifest not found: $app_manifest"
    fi
    
    # Apply the manifest
    kubectl apply -f "$app_manifest" -n argocd || \
        error_exit "Failed to deploy $app_name"
    
    success_msg "$app_name deployed"
    
    # Wait for ArgoCD to reconcile
    info_msg "Waiting for ArgoCD to reconcile $app_name (timeout: 5 minutes)..."
    if timeout 300s bash -c "
        while true; do
            STATUS=\$(kubectl get application -n argocd -o jsonpath='{.items[?(@.metadata.name==\"${app_name}-app\")].status.operationState.phase}' 2>/dev/null)
            if [[ \"\$STATUS\" == \"Succeeded\" ]]; then
                break
            fi
            sleep 5
        done
    "; then
        success_msg "$app_name reconciliation complete"
    else
        warn_msg "$app_name reconciliation timeout. Check status manually."
    fi
}

# Deploy function based on target
deploy() {
    info_msg "Starting deployment..."
    
    # Create namespaces and RBAC
    create_namespaces
    apply_rbac
    
    # Deploy based on target
    case $DEPLOYMENT_TARGET in
        all)
            deploy_argocd_app "nginx"
            deploy_argocd_app "prometheus"
            ;;
        nginx)
            deploy_argocd_app "nginx"
            ;;
        prometheus)
            deploy_argocd_app "prometheus"
            ;;
    esac
    
    success_msg "Deployment completed successfully!"
}

# Print deployment status
print_status() {
    info_msg "Deployment Status:"
    echo ""
    
    local namespace="argocd-gitops-${ENVIRONMENT}"
    
    kubectl get pods -n "$namespace" --no-headers 2>/dev/null || true
    echo ""
    kubectl get svc -n "$namespace" --no-headers 2>/dev/null || true
    echo ""
    
    # Show ArgoCD app status if available
    if kubectl get applications -n argocd &> /dev/null; then
        echo "${BLUE}ArgoCD Applications:${NC}"
        kubectl get applications -n argocd -o wide 2>/dev/null || true
    fi
}

# Main execution
main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  ArgoCD GitOps Lab - Deployment Script                 ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log "START" "Deployment started"
    log "INFO" "Environment: $ENVIRONMENT | Target: $DEPLOYMENT_TARGET"
    log "INFO" "Log file: $LOG_FILE"
    echo ""
    
    validate_prerequisites
    validate_environment
    validate_deployment_target
    deploy
    print_status
    
    echo ""
    success_msg "Deployment script execution completed!"
    log "END" "Deployment finished successfully"
}

# Run main
main "$@"