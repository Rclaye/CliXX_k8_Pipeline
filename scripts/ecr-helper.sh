#!/bin/bash
# ========================================
# ECR LOGIN AND IMAGE PUSH HELPER
# Usage: ./ecr-helper.sh <action> [image-tag]
# Actions: login, push, pull
# ========================================

set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-924305315126}"
ECR_REPOSITORY="${ECR_REPOSITORY:-clixx-repository2}"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

ACTION=${1:-login}
IMAGE_TAG=${2:-latest}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

case $ACTION in
    login)
        log_info "Logging into ECR..."
        aws ecr get-login-password --region "$AWS_REGION" | \
            docker login --username AWS --password-stdin "$ECR_REGISTRY"
        log_info "Successfully logged into ECR"
        ;;
    
    push)
        log_info "Pushing image to ECR..."
        FULL_IMAGE="${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
        
        # Tag if local image exists
        if docker images | grep -q "$ECR_REPOSITORY.*$IMAGE_TAG"; then
            log_info "Image already tagged: $FULL_IMAGE"
        else
            log_info "Tagging image as: $FULL_IMAGE"
            docker tag "${ECR_REPOSITORY}:${IMAGE_TAG}" "$FULL_IMAGE"
        fi
        
        docker push "$FULL_IMAGE"
        log_info "Successfully pushed: $FULL_IMAGE"
        ;;
    
    pull)
        log_info "Pulling image from ECR..."
        FULL_IMAGE="${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
        docker pull "$FULL_IMAGE"
        log_info "Successfully pulled: $FULL_IMAGE"
        ;;
    
    list)
        log_info "Listing images in ECR repository..."
        aws ecr describe-images \
            --repository-name "$ECR_REPOSITORY" \
            --region "$AWS_REGION" \
            --query 'imageDetails[*].{Tag:imageTags[0],Pushed:imagePushedAt,Size:imageSizeInBytes}' \
            --output table
        ;;
    
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage: $0 <login|push|pull|list> [image-tag]"
        exit 1
        ;;
esac
