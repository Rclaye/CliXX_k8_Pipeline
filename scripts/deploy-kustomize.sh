#!/bin/bash
# ========================================
# DEPLOY KUSTOMIZE MANIFESTS
# Usage: ./deploy-kustomize.sh <environment>
# ========================================

set -euo pipefail

ENVIRONMENT=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="${SCRIPT_DIR}/../k8s"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT"
    echo "Usage: $0 <dev|staging|prod>"
    exit 1
fi

log_info "Deploying to environment: $ENVIRONMENT"

# Check if kustomize is available (built into kubectl 1.14+)
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl not found. Please install kubectl."
    exit 1
fi

# Validate kustomize overlay exists
OVERLAY_DIR="${K8S_DIR}/overlays/${ENVIRONMENT}"
if [[ ! -d "$OVERLAY_DIR" ]]; then
    log_error "Overlay directory not found: $OVERLAY_DIR"
    exit 1
fi

# Validate the manifests
log_info "Validating Kustomize manifests..."
if ! kubectl kustomize "$OVERLAY_DIR" > /dev/null 2>&1; then
    log_error "Kustomize validation failed!"
    kubectl kustomize "$OVERLAY_DIR"
    exit 1
fi

# Show diff before applying (if cluster is accessible)
log_info "Showing diff..."
kubectl diff -k "$OVERLAY_DIR" 2>/dev/null || true

# Prompt for confirmation in prod
if [[ "$ENVIRONMENT" == "prod" ]]; then
    log_warn "You are deploying to PRODUCTION!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        log_info "Deployment cancelled."
        exit 0
    fi
fi

# Apply the manifests
log_info "Applying Kustomize manifests..."
kubectl apply -k "$OVERLAY_DIR"

# Wait for rollout
log_info "Waiting for deployment rollout..."
NAMESPACE="clixx-${ENVIRONMENT}"
kubectl rollout status deployment/clixx-web-deployment-${ENVIRONMENT} \
    -n "$NAMESPACE" \
    --timeout=300s || {
        log_error "Rollout failed or timed out!"
        log_info "Rolling back..."
        kubectl rollout undo deployment/clixx-web-deployment-${ENVIRONMENT} -n "$NAMESPACE"
        exit 1
    }

# Show deployment status
log_info "Deployment successful!"
echo ""
kubectl get pods -n "$NAMESPACE" -l app=clixx-web-app
echo ""
kubectl get svc -n "$NAMESPACE"

log_info "Done!"
