# General settings
aws_region  = "us-east-1"
environment = "prod"

# VPC and network settings - updated for comprehensive networking
vpc_cidr             = "10.0.0.0/16"
# Scaled down to just 2 AZs for simpler deployment
availability_zones   = ["us-east-1a", "us-east-1b"]

# Subnet CIDR blocks - updated for 2 AZs only
public_subnet_cidrs  = [
  "10.0.0.0/23", "10.0.2.0/23"
]

private_app_subnet_cidrs = [
  "10.0.6.0/24", "10.0.7.0/24"
]

private_db_subnet_cidrs = [
  "10.0.12.0/22", "10.0.16.0/22"
]

private_oracle_subnet_cidrs = [
  "10.0.24.0/24", "10.0.25.0/24"
]

private_java_app_subnet_cidrs = [
  "10.0.27.0/26", "10.0.27.64/26"
]

private_java_db_subnet_cidrs = [
  "10.0.28.0/26", "10.0.28.64/26"
]

# Bastion host configuration
bastion_instance_type = "t3.micro"
bastion_key_name = "stack_devops_dev_kp"
bastion_ssh_key_path = "/Users/richardclaye/Downloads/CREDS/stack_devops_dev_kp.pem"
private_instance_ssh_key_path = "/Users/richardclaye/Downloads/CREDS/myec2kp_priv.pem"
private_instance_ssh_key_destination_filename_on_bastion = "myec2kp_priv.pem"

bastion_allowed_cidrs = ["0.0.0.0/0"]  

# Security settings
admin_ips = ["0.0.0.0/0"] # Update with specific IPs for better security

# Database settings 
db_name              = "wordpressdb"
db_user              = "wordpressuser"
db_password          = "W3lcome123"
db_instance_class    = "db.t3.micro"
db_snapshot_identifier = "arn:aws:rds:us-east-1:924305315126:snapshot:wordpressdbclixxjenkins-1"

# EC2 settings
ec2_instance_type    = "t2.micro" 
ec2_key_name         = "stack_devops_dev_kp"
private_key_name     = "myec2kp_priv"  # Add this line to specify the private key name

# Auto Scaling settings
min_size         = 1 # Reduced to 1 for cost savings
max_size         = 2 # Reduced to 2 for cost savings
desired_capacity = 1 # Reduced to 1 for cost savings

# Domain settings - simplified to match the 4-subnet deployment
domain_name             = "stack-claye.com"
hosted_zone_name        = "stack-claye.com"
new_record              = "ecs"
create_dns_record       = true
create_existing_record  = false  # Keep this false as we only need the subdomain record

# SSL Certificate configuration
certificate_arn = "arn:aws:acm:us-east-1:924305315126:certificate/359f0a6c-455b-4b1d-9b95-462ffd90a2b9"
certificate_domain = "*.stack-claye.com"

# WordPress Admin credentials - From infra-setup.sh
wp_admin_user     = "clixxadmin"
wp_admin_password = "Stack#25!"
wp_admin_email    = "richard.claye@gmail.com"

# ECR Repository settings (Used for K8s image pulls)
ecr_repository_name = "clixx-repository2"
ecr_repository_url  = "924305315126.dkr.ecr.us-east-1.amazonaws.com/clixx-repository2"
ecr_image_tag       = "clixx-image-1.0.42"  # Updated to match your clixx-deployment.yaml

target_account_id = "924305315126" # Engineering account ID for cross-account access
target_role_name = "Engineer"
