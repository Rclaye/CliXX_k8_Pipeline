# ========================================
# KUBERNETES IAM RESOURCES
# ========================================

# IAM Role for K8s EC2 instances
resource "aws_iam_role" "k8s_instance_role" {
  name = "clixx-k8s-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = merge(var.common_tags, { Name = "clixx-k8s-instance-role" })
}

# ECR Read-Only access (Essential for pulling your CliXX image)
resource "aws_iam_role_policy_attachment" "k8s_ecr_policy" {
  role       = aws_iam_role.k8s_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# SSM access (Essential for Session Manager access if SSH fails)
resource "aws_iam_role_policy_attachment" "k8s_ssm_policy" {
  role       = aws_iam_role.k8s_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Add SSM write policy for storing join command
resource "aws_iam_role_policy" "k8s_ssm_write" {
  name = "clixx-k8s-ssm-write-policy"
  role = aws_iam_role.k8s_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssm:PutParameter",
        "ssm:GetParameter",
        "ssm:DeleteParameter",
        "ssm:AddTagsToResource"
      ]
      Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/clixx/*"
    }]
  })
}

# Instance Profile
resource "aws_iam_instance_profile" "k8s_instance_profile" {
  name = "clixx-k8s-instance-profile"
  role = aws_iam_role.k8s_instance_role.name
}

# ========================================
# EC2 INSTANCES
# ========================================

# --- MASTER NODE ---
resource "aws_instance" "k8s_master" {
  ami                    = var.k8s_ami_id
  instance_type          = var.k8s_master_instance_type
  subnet_id              = aws_subnet.private_app[0].id
  key_name               = var.private_key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.k8s_instance_profile.name

  # Use templatefile with variables
  user_data = templatefile("${path.module}/master_combined.sh", {
    aws_region         = var.aws_region
    ecr_repository_url = var.ecr_repository_url
    deployment_yaml    = file("${path.module}/clixx-deployment.yaml")
    service_yaml       = file("${path.module}/clixx-service.yaml")
  })

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = merge(var.common_tags, {
    Name      = "clixx-k8s-master"
    Role      = "control-plane"
    ManagedBy = "Terraform"
  })

  depends_on = [
    aws_nat_gateway.nat_gw,
    aws_route_table_association.private_app_rta
  ]
}

# --- WORKER NODES ---
resource "aws_instance" "k8s_workers" {
  count                  = var.k8s_worker_count
  ami                    = var.k8s_ami_id
  instance_type          = var.k8s_worker_instance_type
  subnet_id              = element(aws_subnet.private_app[*].id, count.index)
  key_name               = var.private_key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.k8s_instance_profile.name

  # Use templatefile with aws_region variable
  user_data = templatefile("${path.module}/worker_combined.sh", {
    aws_region = var.aws_region
  })

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = merge(var.common_tags, {
    Name      = "clixx-k8s-worker-${count.index + 1}"
    Role      = "worker"
    ManagedBy = "Terraform"
  })

  depends_on = [
    aws_nat_gateway.nat_gw,
    aws_route_table_association.private_app_rta,
    aws_instance.k8s_master
  ]
}

# ========================================
# OUTPUTS
# ========================================

output "grafana_url" {
  description = "URL to access Grafana dashboard"
  value       = "https://grafana.stack-claye.com"
}