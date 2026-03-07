#!/bin/bash
# ========================================
# REFRESH ECR CREDENTIALS IN K8S
# Run this as a cron job every 10 hours
# ========================================

set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
ECR_REGISTRY="${ECR_REGISTRY:-924305315126.dkr.ecr.us-east-1.amazonaws.com}"
NAMESPACE="${NAMESPACE:-clixx}"
SECRET_NAME="ecr-registry-secret"

log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1"; }

log_info "Refreshing ECR credentials..."

# Get new ECR password
ECR_PASSWORD=$(aws ecr get-login-password --region "$AWS_REGION")

if [[ -z "$ECR_PASSWORD" ]]; then
    log_error "Failed to get ECR password"
    exit 1
fi

# Update the secret in all namespaces where it exists
for ns in clixx clixx-dev clixx-staging clixx-prod; do
    if kubectl get namespace "$ns" &>/dev/null; then
        log_info "Updating secret in namespace: $ns"
        kubectl create secret docker-registry "$SECRET_NAME" \
            --namespace="$ns" \
            --docker-server="$ECR_REGISTRY" \
            --docker-username=AWS \
            --docker-password="$ECR_PASSWORD" \
            --dry-run=client -o yaml | kubectl apply -f -
    fi
done

log_info "ECR credentials refreshed successfully"
