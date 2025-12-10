#!/bin/bash
# ========================================
# COMBINED WORKER NODE SCRIPT
# Part 1: Install K8s tools
# Part 2: Join cluster
# ========================================

set -e
exec > >(tee /var/log/combined-worker-init.log|logger -t combined-worker -s 2>/dev/console) 2>&1

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

sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

sudo apt-get install -y ca-certificates gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y containerd.io

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

sudo apt-get install -y apt-transport-https ca-certificates curl gpg

sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable kubelet

echo "=========================================="
echo "PART 2: Joining Kubernetes Cluster"
echo "=========================================="

# Set hostname based on private IP last octet
WORKER_IP=$(hostname -I | awk '{print $1}')
LAST_OCTET=$(echo $WORKER_IP | cut -d. -f4)

# Simple logic: if IP ends in 35 → worker1, if 33 → worker2
if [ "$LAST_OCTET" -eq 35 ]; then
    HOSTNAME="k8_Worker1"
elif [ "$LAST_OCTET" -eq 33 ]; then
    HOSTNAME="k8_Worker2"
else
    HOSTNAME="k8_Worker$LAST_OCTET"  # Fallback
fi

sudo hostnamectl set-hostname $HOSTNAME
echo "$WORKER_IP $HOSTNAME" | sudo tee -a /etc/hosts

# Wait for kubelet
for i in {1..30}; do
    if systemctl is-active --quiet kubelet; then
        echo "Kubelet is active"
        break
    fi
    sleep 10
done

# Wait for join command in SSM
for i in {1..60}; do
    JOIN_COMMAND=$(aws ssm get-parameter \
        --name "/clixx/k8s-join-command" \
        --query "Parameter.Value" \
        --output text \
        --region ${aws_region} 2>/dev/null || echo "")
    
    if [ -n "$JOIN_COMMAND" ] && [ "$JOIN_COMMAND" != "None" ]; then
        echo "Join command retrieved!"
        break
    fi
    echo "Waiting for master... ($i/60)"
    sleep 30
done

if [ -z "$JOIN_COMMAND" ] || [ "$JOIN_COMMAND" == "None" ]; then
    echo "ERROR: No join command found"
    exit 1
fi

# Join cluster
sudo $JOIN_COMMAND

echo "=========================================="
echo "WORKER $HOSTNAME JOINED CLUSTER SUCCESSFULLY!"
echo "=========================================="
