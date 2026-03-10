#!/bin/bash

################################################################################
# ArgoCD GitOps Lab - Rollback Script
# Purpose: Rollback applications to previous revision with validation
# Usage: ./rollback.sh [dev|prod] [app-name] [revision]
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${PROJECT_ROOT}/rollback-$(date +%Y%m%d_%H%M%S).log"

# Default values
ENVIRONMENT="${1:-dev}"
APP_NAME="${2:-nodejs-app}"
TARGET_REVISION="${3:-}"

# Logging function
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

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
    
    if ! command -v kubectl &> /dev/null; then
        error_exit "kubectl not found"
    fi
    success_msg "kubectl found"
    
    if ! command -v git &> /dev/null; then
        error_exit "git not found"
    fi
    success_msg "git found"
    
    if ! kubectl cluster-info &> /dev/null; then
        error_exit "Cannot connect to Kubernetes cluster"
    fi
    success_msg "Kubernetes cluster accessible"
}

# Get revision history
get_revision_history() {
    local app_name=$1
    
    info_msg "Fetching revision history for $app_name..."
    
    if ! kubectl get application "$app_name" -n argocd &> /dev/null; then
        error_exit "Application $app_name not found in argocd namespace"
    fi
    
    # Get history from application manifest
    kubectl get application "$app_name" -n argocd -o jsonpath='{.status.history}' 2>/dev/null || \
        error_exit "Could not retrieve revision history"
}

# List available revisions
list_revisions() {
    local app_name=$1
    
    echo ""
    echo -e "${CYAN}Available Revisions for $app_name:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Get and display history
    kubectl get application "$app_name" -n argocd -o jsonpath='{range .status.history[*]}{.revision}{"\t"}{.deployedAt}{"\t"}{.source.repoURL}{"\n"}{end}' 2>/dev/null || true
    
    echo ""
}

# Show current state
show_current_state() {
    local app_name=$1
    
    echo ""
    echo -e "${CYAN}Current State of $app_name:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    kubectl get application "$app_name" -n argocd -o wide
    
    echo ""
}

# Perform rollback
perform_rollback() {
    local app_name=$1
    local revision=$2
    
    info_msg "Performing rollback of $app_name to revision $revision..."
    
    # Confirm rollback
    echo ""
    echo -e "${YELLOW}⚠ ROLLBACK CONFIRMATION${NC}"
    echo "Application: $app_name"
    echo "Target Revision: $revision"
    echo ""
    read -p "Are you sure you want to rollback? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        warn_msg "Rollback cancelled by user"
        exit 0
    fi
    
    # Use ArgoCD CLI if available
    if command -v argocd &> /dev/null; then
        info_msg "Using argocd CLI for rollback..."
        argocd app rollback "$app_name" "$revision" || \
            error_exit "Failed to rollback $app_name"
    else
        # Fallback to kubectl patch
        info_msg "Using kubectl for rollback..."
        # This is a simplified approach - may need customization for your setup
        kubectl patch application "$app_name" -n argocd \
            -p "{\"spec\":{\"source\":{\"targetRevision\":\"$revision\"}}}" \
            --type merge || error_exit "Failed to patch application"
    fi
    
    success_msg "Rollback command executed"
    
    # Wait for rollback to complete
    info_msg "Waiting for rollback to complete (timeout: 5 minutes)..."
    if timeout 300s bash -c "
        while true; do
            STATUS=\$(kubectl get application -n argocd -o jsonpath='{.items[?(@.metadata.name==\"${app_name}\")].status.operationState.phase}' 2>/dev/null)
            if [[ \"\$STATUS\" == \"Succeeded\" ]]; then
                break
            fi
            sleep 5
        done
    "; then
        success_msg "Rollback completed successfully"
    else
        warn_msg "Rollback timeout. Check status manually."
    fi
}

# Verify rollback
verify_rollback() {
    local app_name=$1
    local namespace=$2
    
    info_msg "Verifying rollback..."
    
    echo ""
    echo -e "${CYAN}Application Status After Rollback:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    kubectl get application "$app_name" -n argocd -o wide
    
    echo ""
    echo -e "${CYAN}Pod Status in $namespace:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    kubectl get pods -n "$namespace" -o wide 2>/dev/null || warn_msg "Namespace not found"
    
    echo ""
}

# Main execution
main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  ArgoCD GitOps Lab - Rollback Script                   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log "START" "Rollback script started"
    log "INFO" "Environment: $ENVIRONMENT | App: $APP_NAME"
    log "INFO" "Log file: $LOG_FILE"
    
    # Validate environment
    if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
        error_exit "Invalid environment: $ENVIRONMENT"
    fi
    
    validate_prerequisites
    show_current_state "$APP_NAME"
    list_revisions "$APP_NAME"
    
    # Get or prompt for revision
    if [[ -z "$TARGET_REVISION" ]]; then
        echo -e "${YELLOW}No revision specified. Defaulting to previous revision.${NC}"
        TARGET_REVISION="0"  # '0' typically means previous revision in ArgoCD
        read -p "Enter revision number (or press Enter for previous): " user_revision
        if [[ -n "$user_revision" ]]; then
            TARGET_REVISION="$user_revision"
        fi
    fi
    
    perform_rollback "$APP_NAME" "$TARGET_REVISION"
    
    # Small delay for system to settle
    sleep 10
    
    verify_rollback "$APP_NAME" "argocd-gitops-${ENVIRONMENT}"
    
    echo ""
    success_msg "Rollback script completed!"
    log "END" "Rollback script finished"
}

main "$@"