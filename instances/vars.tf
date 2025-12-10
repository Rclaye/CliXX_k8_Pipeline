# General variables
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {
    Project     = "Clixx Retail"
    ManagedBy   = "Terraform"
  }
}

# Network variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

# Updated subnet CIDR variables to match 2-AZ requirements
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (450 hosts each)"
  type        = list(string)
  default     = [
    "10.0.0.0/23", "10.0.2.0/23"  # 512 IPs each - sufficient for 450+ hosts
  ]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets (250 hosts each)"
  type        = list(string)
  default     = [
    "10.0.6.0/24", "10.0.7.0/24"  # 256 IPs each - sufficient for 250+ hosts
  ]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets (680 hosts each)"
  type        = list(string)
  default     = [
    "10.0.12.0/22", "10.0.16.0/22"  # 1024 IPs each - sufficient for 680+ hosts
  ]
}

variable "private_oracle_subnet_cidrs" {
  description = "CIDR blocks for private Oracle database subnets (254 hosts each)"
  type        = list(string)
  default     = [
    "10.0.24.0/24", "10.0.25.0/24"  # 256 IPs each - sufficient for 254 hosts
  ]
}

variable "private_java_app_subnet_cidrs" {
  description = "CIDR blocks for private Java application subnets (50 hosts each)"
  type        = list(string)
  default     = [
    "10.0.27.0/26", "10.0.27.64/26"  # 64 IPs each - sufficient for 50 hosts
  ]
}

variable "private_java_db_subnet_cidrs" {
  description = "CIDR blocks for private Java database subnets (50 hosts each)"
  type        = list(string)
  default     = [
    "10.0.28.0/26", "10.0.28.64/26"  # 64 IPs each - sufficient for 50 hosts
  ]
}

# Application AMI variables
variable "app_ami_id" {
  description = "AMI ID built by Packer for the application"
  type        = string
  default     = "" # Default is empty, will be provided by Jenkins pipeline
}

# Bastion Configuration Variables
variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t2.micro"
}

variable "bastion_ami_id" {
  description = "AMI ID for the bastion host (defaults to ec2_ami if empty)"
  type        = string
  default     = "ami-0ecb62995f68bb549"  # Ubuntu AMI
}

variable "bastion_key_name" {
  description = "Key pair name for the bastion host"
  type        = string
  default     = "stack_devops_dev_kp"  # Default to same as ec2_key_name
}

variable "private_instance_ssh_key_destination_filename_on_bastion" {
  description = "Filename for the private instance SSH key on the bastion host"
  type        = string
  default     = "myec2kp_priv.pem"  # Updated to match terraform.tfvars
}

variable "bastion_ssh_key_path" {
  description = "Local path to the SSH private key for the bastion host"
  type        = string
  default     = "/Users/richardclaye/Downloads/CREDS/stack_devops_dev_kp.pem"
}

variable "private_instance_ssh_key_path" {
  description = "Local path to the SSH private key for private instances (to be copied to bastion)"
  type        = string
  default     = "/Users/richardclaye/Downloads/CREDS/myec2kp_priv.pem"
}

variable "bastion_allowed_cidrs" {
  description = "CIDR blocks allowed to connect to bastion via SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Consider restricting for production
}

# Security variables
variable "admin_ips" {
  description = "List of IP addresses allowed to access admin resources"
  type        = list(string)
}

# Database variables
variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "wordpressdb"  # Updated to match the Clixx application
}

variable "db_user" {
  description = "Username for database access"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password for database access"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
}

variable "db_snapshot_identifier" {
  description = "Snapshot identifier for RDS instance restoration"
  type        = string
  default     = ""  # Remove the hardcoded ARN to make it more configurable
}

# EC2 variables
variable "ec2_instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
}

variable "private_key_name" {
  description = "Name of SSH key pair for private EC2 instances"
  type        = string
  default     = "myec2kp_priv"
}

variable "ec2_key_name" {
  description = "Name of SSH key pair for EC2 instances (used for public instances)"
  type        = string
  default     = "stack_devops_dev_kp"
}

variable "ec2_ami" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0ecb62995f68bb549" # Amazon Linux 2 AMI ID - latest version
}

# Auto Scaling variables
variable "min_size" {
  description = "Minimum size for Auto Scaling Group"
  type        = number
  default     = 1  # Updated default to 1 for cost savings
}

variable "max_size" {
  description = "Maximum size for Auto Scaling Group"
  type        = number
  default     = 2  # Updated default to 2 for cost savings
}

variable "desired_capacity" {
  description = "Desired capacity for Auto Scaling Group"
  type        = number
  default     = 1  # Updated default to 1 for cost savings
}

# Domain and DNS variables
variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of SSL certificate in ACM for HTTPS support"
  type        = string
}

variable "certificate_domain" {
  description = "Domain name on the ACM certificate to use with the load balancer"
  type        = string
  default     = "*.stack-claye.com"
}

variable "hosted_zone_name" {
  description = "Name of the Route 53 hosted zone"
  type        = string
  default     = "stack-claye.com" 
}

variable "create_existing_record" {
  description = "Whether to create a record for the root domain"
  type        = bool
  default     = false
}

variable "new_record" {
  description = "New subdomain record to be created in Route 53"
  type        = string
  default     = "ecs"
}

variable "hosted_zone_record_name" {
  description = "Name of the record to create in the hosted zone"
  type        = string
  default     = "ecs.stack-claye.com"
}

variable "create_dns_record" {
  description = "Whether to create a DNS record"
  type        = bool
  default     = true  # Updated default to true
}

# WordPress Admin variables
variable "wp_admin_user" {
  description = "WordPress admin username"
  type        = string
  sensitive   = true
}

variable "wp_admin_password" {
  description = "WordPress admin password"
  type        = string
  sensitive   = true
}

variable "wp_admin_email" {
  description = "WordPress admin email"
  type        = string
  sensitive   = true
}

# ========================================
# ECR SETTINGS (Used for K8s image pulls)
# These are needed to create the ECR pull secret in Kubernetes
# ========================================

variable "ecr_repository_name" {
  description = "Name of the ECR repository for Clixx application"
  type        = string
  default     = "clixx-repository2"
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository (used for K8s imagePullSecrets)"
  type        = string
  default     = "924305315126.dkr.ecr.us-east-1.amazonaws.com/clixx-repository2"
}

variable "ecr_image_tag" {
  description = "The tag of the Docker image to deploy from ECR"
  type        = string
  default     = "latest"
}

# ========================================
# KUBERNETES CONFIGURATION
# ========================================

variable "k8s_master_instance_type" {
  description = "Instance type for K8s Master"
  type        = string
  default     = "t3.medium" # Minimum for K8s Master
}

variable "k8s_worker_instance_type" {
  description = "Instance type for K8s Workers"
  type        = string
  default     = "t3.large" # Enough RAM for App + Prometheus stack
}

variable "k8s_ami_id" {
  description = "Ubuntu 22.04 or 24.04 AMI ID for K8s nodes"
  type        = string
  default     = "ami-0ecb62995f68bb549"  # Ubuntu AMI
}

variable "k8s_worker_count" {
  description = "Number of K8s worker nodes"
  type        = number
  default     = 2
}

# ========================================
# CROSS-ACCOUNT ACCESS CONFIGURATION
# ========================================

# Cross-account access variables
variable "target_account_id" {
  description = "The AWS Account ID to assume the role into (Development Account)"
  type        = string
}

variable "target_role_name" {
  description = "Name of the IAM role to assume in the target account"
  type        = string
  default     = "Engineer"
}