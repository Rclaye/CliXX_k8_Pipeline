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
# SSH ACCESS COMMANDS
# ========================================

output "ssh_to_master_via_bastion" {
  description = "Command to SSH to K8s Master via Bastion"
  value       = "ssh -i ${var.private_instance_ssh_key_path} -o ProxyCommand=\"ssh -i ${var.bastion_ssh_key_path} -W %h:%p ubuntu@${aws_instance.bastion[0].public_ip}\" ubuntu@${aws_instance.k8s_master.private_ip}"
}

output "ssh_to_worker1_via_bastion" {
  description = "Command to SSH to K8s Worker 1 via Bastion"
  value       = "ssh -i ${var.private_instance_ssh_key_path} -o ProxyCommand=\"ssh -i ${var.bastion_ssh_key_path} -W %h:%p ubuntu@${aws_instance.bastion[0].public_ip}\" ubuntu@${aws_instance.k8s_workers[0].private_ip}"
}

# ========================================
# ECR CONFIGURATION
# ========================================

output "ecr_repository_url" {
  description = "ECR repository URL for K8s deployments"
  value       = var.ecr_repository_url
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
    grafana_access     = "ssh -i ${var.private_instance_ssh_key_path} -o ProxyCommand=\"ssh -i ${var.bastion_ssh_key_path} -W %h:%p ubuntu@${aws_instance.bastion[0].public_ip}\" -L 8080:${aws_instance.k8s_workers[0].private_ip}:31000 ubuntu@${aws_instance.k8s_master.private_ip}"
    grafana_url        = "http://localhost:8080"
    grafana_login      = "admin/admin123"
  }
}

# ========================================
# GRAFANA MONITORING ACCESS
# ========================================

output "grafana_access_instructions" {
  description = "How to access Grafana monitoring dashboard"
  value = <<-EOT
    
    ============================================
    GRAFANA MONITORING ACCESS
    ============================================
    
    ✅ FULLY AUTOMATED - Grafana installed via Helm
    
    SSH Port Forward Command:
    ============================================
    ssh -i ${var.private_instance_ssh_key_path} \
      -o ProxyCommand="ssh -i ${var.bastion_ssh_key_path} -W %h:%p ubuntu@${aws_instance.bastion[0].public_ip}" \
      -L 8080:${aws_instance.k8s_workers[0].private_ip}:31000 \
      ubuntu@${aws_instance.k8s_master.private_ip}
    
    Then visit: http://localhost:8080
    Login: admin / admin123
    
    ============================================
    Cluster Status Commands (on master):
    ============================================
    kubectl get nodes
    kubectl get pods -A
    kubectl get svc -n monitoring
    
    ============================================
  EOT
}

# ========================================
# AUTOMATION STATUS
# ========================================

output "automation_summary" {
  description = "What was automated in this deployment"
  value = <<-EOT
    
    ============================================
    AUTOMATED DEPLOYMENT COMPLETE! 🎉
    ============================================
    
    ✅ VPC with 12 subnets across 2 AZs
    ✅ RDS MySQL (Multi-AZ) restored from snapshot
    ✅ K8s Master initialized with kubeadm
    ✅ Weave CNI network plugin installed
    ✅ 2 Worker nodes joined via SSM
    ✅ ECR image pull secret created
    ✅ CliXX app deployed (2 replicas)
    ✅ Prometheus + Grafana monitoring stack
    ✅ ALB routing traffic to NodePort 30000
    ✅ Route53 DNS record: ecs.stack-claye.com
    ✅ HTTPS via ACM certificate
    
    Application: https://ecs.stack-claye.com
    Bastion: ${aws_instance.bastion[0].public_ip}
    Master: ${aws_instance.k8s_master.private_ip}
    Workers: ${join(", ", aws_instance.k8s_workers[*].private_ip)}
    
    ============================================
  EOT
}
