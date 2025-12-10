#!/bin/bash
# ========================================
# COMBINED MASTER NODE SCRIPT
# Part 1: Install K8s tools
# Part 2: Initialize cluster, deploy app, AND MONITORING
# ========================================

set -e
exec > >(tee /var/log/combined-master-init.log|logger -t combined-master -s 2>/dev/console) 2>&1

echo "=========================================="
echo "PART 0: Installing AWS CLI FIRST"
echo "=========================================="

# Install AWS CLI FIRST (needed for SSM commands)
sudo apt-get update
sudo apt-get install -y unzip curl
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws/

# Verify AWS CLI works
aws --version

echo "=========================================="
echo "PART 1: Installing Kubernetes Tools"
echo "=========================================="

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
echo "Instance ID: $INSTANCE_ID"

# Disable Swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Networking Modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Sysctl params
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Containerd Prerequisites
sudo apt-get install -y ca-certificates gnupg

# Docker Repo & GPG
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Containerd
sudo apt-get update
sudo apt-get install -y containerd.io

# Configure Containerd with Cgroups
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Install Kube tools
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable kubelet

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "=========================================="
echo "PART 2: Initializing Master Node"
echo "=========================================="

# Initialize Cluster
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=NumCPU,Mem

# Configure kubectl for ubuntu user
mkdir -p /home/ubuntu/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Install WeaveNet CNI
sudo -u ubuntu kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

# Wait for Weave to be ready
echo "Waiting for CNI..."
sleep 60

# Store join command in SSM
JOIN_COMMAND=$(sudo kubeadm token create --print-join-command)
aws ssm put-parameter \
    --name "/clixx/k8s-join-command" \
    --value "$JOIN_COMMAND" \
    --type "String" \
    --overwrite \
    --region ${aws_region}

# Create ECR Secret
ECR_PASSWORD=$(aws ecr get-login-password --region ${aws_region})
sudo -u ubuntu kubectl create secret docker-registry ecr-registry-secret \
    --docker-server="${ecr_repository_url}" \
    --docker-username=AWS \
    --docker-password="$ECR_PASSWORD" \
    --dry-run=client -o yaml | sudo -u ubuntu kubectl apply -f -

# Write Manifest Files
cat <<'DEPLOYMENT_EOF' | sudo -u ubuntu tee /home/ubuntu/clixx-deployment.yaml
${deployment_yaml}
DEPLOYMENT_EOF

cat <<'SERVICE_EOF' | sudo -u ubuntu tee /home/ubuntu/clixx-service.yaml
${service_yaml}
SERVICE_EOF

# Deploy App
echo "Deploying Application..."
sudo -u ubuntu kubectl apply -f /home/ubuntu/clixx-deployment.yaml
sudo -u ubuntu kubectl apply -f /home/ubuntu/clixx-service.yaml

echo "=========================================="
echo "PART 3: Install Monitoring Stack"
echo "=========================================="

# Add Repo
sudo -u ubuntu helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
sudo -u ubuntu helm repo update

# Create Namespace
sudo -u ubuntu kubectl create namespace monitoring --dry-run=client -o yaml | sudo -u ubuntu kubectl apply -f -

# Install Prometheus/Grafana via Helm
sudo -u ubuntu helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --set grafana.enabled=true \
    --set grafana.adminPassword=admin123 \
    --set grafana.service.type=NodePort \
    --set grafana.service.nodePort=31000 \
    --wait --timeout 15m || echo "Monitoring install failed but continuing..."

echo "=========================================="
echo "MASTER INITIALIZATION COMPLETE!"
echo "=========================================="
sudo -u ubuntu kubectl get nodes
sudo -u ubuntu kubectl get pods -A