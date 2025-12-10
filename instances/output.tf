# Consolidated Outputs for Clixx Kubernetes Infrastructure

# ========================================
# VPC OUTPUTS
# ========================================

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "availability_zones_used" {
  description = "List of Availability Zones used for the subnets"
  value       = var.availability_zones
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "List of private application subnet IDs"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "List of private database subnet IDs"
  value       = aws_subnet.private_db[*].id
}

output "private_oracle_subnet_ids" {
  description = "List of private Oracle subnet IDs"
  value       = aws_subnet.private_oracle[*].id
}

output "private_java_app_subnet_ids" {
  description = "List of private Java application subnet IDs"
  value       = aws_subnet.private_java_app[*].id
}

output "private_java_db_subnet_ids" {
  description = "List of private Java database subnet IDs"
  value       = aws_subnet.private_java_db[*].id
}

output "nat_gateway_ips" {
  description = "Elastic IP addresses of NAT gateways"
  value       = aws_eip.nat[*].public_ip
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public_rt.id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private_rt[*].id
}

# ========================================
# SECURITY GROUP OUTPUTS
# ========================================

output "bastion_security_group_id" {
  description = "The ID of the Bastion security group"
  value       = aws_security_group.bastion_sg.id
}

output "k8s_security_group_id" {
  description = "The ID of the K8s nodes security group"
  value       = aws_security_group.k8s_sg.id
}

output "k8s_alb_security_group_id" {
  description = "The ID of the K8s ALB security group"
  value       = aws_security_group.k8s_alb_sg.id
}

output "rds_security_group_id" {
  description = "The ID of the RDS security group"
  value       = aws_security_group.rds_sg.id
}

# ========================================
# KUBERNETES CLUSTER OUTPUTS
# ========================================

output "k8s_master_private_ip" {
  description = "Private IP of the K8s Master node"
  value       = aws_instance.k8s_master.private_ip
}

output "k8s_master_id" {
  description = "Instance ID of the K8s Master node"
  value       = aws_instance.k8s_master.id
}

output "k8s_worker_private_ips" {
  description = "Private IPs of the K8s Worker nodes"
  value       = aws_instance.k8s_workers[*].private_ip
}

output "k8s_worker_ids" {
  description = "Instance IDs of the K8s Worker nodes"
  value       = aws_instance.k8s_workers[*].id
}

# ========================================
# LOAD BALANCER OUTPUTS
# ========================================

output "k8s_alb_id" {
  description = "The ID of the K8s Load Balancer"
  value       = aws_lb.k8s_alb.id
}

output "k8s_alb_arn" {
  description = "The ARN of the K8s Load Balancer"
  value       = aws_lb.k8s_alb.arn
}

output "k8s_alb_dns_name" {
  description = "DNS name of the K8s Application Load Balancer"
  value       = aws_lb.k8s_alb.dns_name
}

output "k8s_alb_zone_id" {
  description = "Zone ID of the K8s ALB"
  value       = aws_lb.k8s_alb.zone_id
}

output "k8s_target_group_arn" {
  description = "The ARN of the K8s Target Group"
  value       = aws_lb_target_group.k8s_tg.arn
}

# ========================================
# DATABASE OUTPUTS
# ========================================

output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.clixx_db.endpoint
}

output "rds_address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.clixx_db.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.clixx_db.port
}

output "rds_db_name" {
  description = "The database name of the RDS instance"
  value       = aws_db_instance.clixx_db.db_name
}

output "db_connection_string" {
  description = "Complete RDS connection string"
  value       = "${aws_db_instance.clixx_db.address}:${aws_db_instance.clixx_db.port}/${aws_db_instance.clixx_db.db_name}"
  sensitive   = true
}

output "rds_engine_version" {
  description = "The version of the RDS engine"
  value       = aws_db_instance.clixx_db.engine_version
}

output "rds_multi_az" {
  description = "Whether RDS is configured for Multi-AZ deployment"
  value       = aws_db_instance.clixx_db.multi_az
}

output "rds_subnet_group" {
  description = "The subnet group used by the RDS instance"
  value       = aws_db_instance.clixx_db.db_subnet_group_name
}

# ========================================
# DNS OUTPUTS
# ========================================

output "route53_zone_id" {
  description = "The ID of the hosted zone"
  value       = data.aws_route53_zone.clixx_zone.zone_id
}

output "route53_record_name" {
  description = "The name of the Route 53 record"
  value       = aws_route53_record.k8s_record.name
}

output "route53_record_fqdn" {
  description = "The FQDN of the Route 53 record"
  value       = aws_route53_record.k8s_record.fqdn
}

output "application_url" {
  description = "URL to access the CliXX application"
  value       = "https://ecs.stack-claye.com"
}

output "website_url" {
  description = "URL to access the website"
  value       = "https://ecs.stack-claye.com"
}

# ========================================
# CERTIFICATE OUTPUTS
# ========================================

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = data.aws_acm_certificate.clixx_cert.arn
}

output "certificate_domain_name" {
  description = "Domain name of the certificate"
  value       = data.aws_acm_certificate.clixx_cert.domain
}

# ========================================
# IAM OUTPUTS
# ========================================

output "k8s_instance_profile_name" {
  description = "Name of the IAM instance profile for K8s nodes"
  value       = aws_iam_instance_profile.k8s_instance_profile.name
}

output "k8s_instance_role_arn" {
  description = "ARN of the IAM role for K8s nodes"
  value       = aws_iam_role.k8s_instance_role.arn
}

# ========================================
# BASTION OUTPUTS
# ========================================

output "bastion_public_ip" {
  description = "Public IP of the Bastion host"
  value       = aws_instance.bastion[0].public_ip
}

output "bastion_public_dns" {
  description = "Public DNS of the bastion host"
  value       = aws_instance.bastion[0].public_dns
}

output "bastion_ssh_command" {
  description = "Command to SSH into the bastion host"
  value       = "ssh -i ${var.bastion_ssh_key_path} ubuntu@${aws_instance.bastion[0].public_ip}"
}

# ========================================
# SSH COMMANDS
# ========================================

output "ssh_to_master_via_bastion" {
  description = "Command to SSH to K8s Master via Bastion"
  value       = "ssh -i ${var.private_instance_ssh_key_path} -J ubuntu@${aws_instance.bastion[0].public_ip} ubuntu@${aws_instance.k8s_master.private_ip}"
}

output "ssh_key_transfer_command" {
  description = "Command to transfer the private key to the bastion via SCP"
  value       = "scp -i ${var.bastion_ssh_key_path} ${var.private_instance_ssh_key_path} ubuntu@${aws_instance.bastion[0].public_ip}:~/.ssh/${var.private_instance_ssh_key_destination_filename_on_bastion}"
}

# ========================================
# KUBERNETES SETUP INSTRUCTIONS
# ========================================

output "next_steps" {
  description = "Manual steps to complete K8s setup based on your documentation"
  value       = <<-EOT
    
    ============================================
    POST-TERRAFORM KUBERNETES SETUP STEPS:
    ============================================
    
    BASTION IP: ${aws_instance.bastion[0].public_ip}
    MASTER IP:  ${aws_instance.k8s_master.private_ip}
    WORKER IPs: ${join(", ", aws_instance.k8s_workers[*].private_ip)}
    ALB DNS:    ${aws_lb.k8s_alb.dns_name}
    URL:        https://ecs.stack-claye.com
    
    ============================================
    ℹ️  ALL INSTANCES USING: ami-0ecb62995f68bb549 (Ubuntu)
       New Terraform-managed instances:
       - clixx-k8s-master
       - clixx-k8s-worker-1
       - clixx-k8s-worker-2
    ============================================
    
    STEP 1: LOGIN TO MASTER (Run from your local terminal)
    ============================================
    # Add key to agent
    ssh-add ${var.bastion_ssh_key_path} 
    
    # Jump through bastion to master
    ssh -J ubuntu@${aws_instance.bastion[0].public_ip} ubuntu@${aws_instance.k8s_master.private_ip}
    
    ============================================
    STEP 2: INITIALIZE CLUSTER (On Master)
    ============================================
    sudo kubeadm init
    
    # Run the 3 commands output by kubeadm to configure .kube/config:
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    
    ============================================
    STEP 3: INSTALL WEAVENET CNI (On Master)
    ============================================
    # This matches your manual deployment success
    kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
    
    ============================================
    STEP 4: JOIN WORKERS (On Workers)
    ============================================
    # Get the join command from Master:
    kubeadm token create --print-join-command
    
    # Open new terminal tabs, jump to workers, and run the join command:
    ssh -J ubuntu@${aws_instance.bastion[0].public_ip} ubuntu@<WORKER_IP_1>
    ssh -J ubuntu@${aws_instance.bastion[0].public_ip} ubuntu@<WORKER_IP_2>
    
    ============================================
    STEP 5: DEPLOY CLIXX (On Master)
    ============================================
    # 1. Create ECR Secret (Important!)
    kubectl create secret docker-registry ecr-registry-secret \
      --docker-server=${var.ecr_repository_url} \
      --docker-username=AWS \
      --docker-password=$(aws ecr get-login-password --region ${var.aws_region})
    
    # 2. Deploy App
    kubectl apply -f ~/clixx-deployment.yaml
    kubectl apply -f ~/clixx-service.yaml
    
    ============================================
    STEP 6: MONITORING (On Master)
    ============================================
    # This runs the script based on Christine's guide
    chmod +x ~/install_monitoring.sh
    ~/install_monitoring.sh
    
    ============================================
  EOT
}

# ========================================
# ECR OUTPUTS (For K8s Secret Creation)
# ========================================

output "ecr_repository_url" {
  description = "ECR repository URL for K8s deployments"
  value       = var.ecr_repository_url
}

output "ecr_secret_command" {
  description = "Command to create ECR pull secret in Kubernetes"
  value       = "kubectl create secret docker-registry ecr-registry-secret --docker-server=${var.ecr_repository_url} --docker-username=AWS --docker-password=$(aws ecr get-login-password --region ${var.aws_region})"
}

# ========================================
# DEPLOYMENT SUMMARY
# ========================================

output "deployment_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    vpc_cidr           = aws_vpc.main.cidr_block
    availability_zones = var.availability_zones
    k8s_master_ip      = aws_instance.k8s_master.private_ip
    k8s_worker_ips     = aws_instance.k8s_workers[*].private_ip
    k8s_worker_count   = var.k8s_worker_count
    alb_dns            = aws_lb.k8s_alb.dns_name
    rds_endpoint       = aws_db_instance.clixx_db.address
    rds_multi_az       = aws_db_instance.clixx_db.multi_az
    application_url    = "https://ecs.stack-claye.com"
    bastion_ip         = aws_instance.bastion[0].public_ip
  }
}
