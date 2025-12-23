# VPC 12 subnet infrastructure deployment of the Clixx Application.
# Main.tf file for deploying security groups, RDS instances, Load Balancer, and other resources.

locals {
  custom_tags = {
    owner       = "richard.claye@gmail.com"
    Stackteam   = "StackCloud13"
    CreatedBy   = "Terraform"
  }
  
  # Private subnet IDs for use in resources
  all_private_subnets = concat(
    aws_subnet.private_app[*].id,
    aws_subnet.private_db[*].id,
    aws_subnet.private_oracle[*].id,
    aws_subnet.private_java_app[*].id,
    aws_subnet.private_java_db[*].id
  )

  # Timestamp for snapshot naming to ensure uniqueness
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
}

# ========================================
# DATA SOURCES
# ========================================

# Fetch the existing hosted zone for DNS record creation
data "aws_route53_zone" "clixx_zone" {
  name = var.domain_name
}

# ========================================
# SECURITY GROUPS 
# ========================================

# Security group for the Bastion Host
resource "aws_security_group" "bastion_sg" {
  name        = "clixx-bastion-sg"
  description = "Security group for Bastion Host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from allowed IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "clixx-bastion-sg" }, local.custom_tags)
}

# Security Group for the K8s Load Balancer
resource "aws_security_group" "k8s_alb_sg" {
  name        = "clixx-k8s-alb-sg"
  description = "Security group for Public Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound to K8s Nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "clixx-k8s-alb-sg" })
}

# Security Group for Kubernetes Cluster (Master & Workers)
resource "aws_security_group" "k8s_sg" {
  name        = "clixx-k8s-sg"
  description = "Security group for K8s Master and Workers"
  vpc_id      = aws_vpc.main.id

  # Allow all internal traffic between Master and Workers
  ingress {
    description = "Allow all internal K8s traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Allow SSH from Bastion
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # ========================================
  # CONTROL PLANE PORTS
  # ========================================
  
  # Kubernetes API Server
  ingress {
    description = "Kubernetes API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # etcd server client API
  ingress {
    description = "etcd server client API"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Kubelet API
  ingress {
    description = "Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # kube-scheduler
  ingress {
    description = "kube-scheduler"
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # kube-controller-manager
  ingress {
    description = "kube-controller-manager"
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # ========================================
  # WORKER NODE PORTS
  # ========================================

  # NodePort Services range from ALB
  ingress {
    description     = "NodePort traffic from ALB"
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.k8s_alb_sg.id]
  }

  # NodePort from VPC for internal access
  ingress {
    description = "NodePort traffic from VPC"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Add this new ingress rule for Grafana
  ingress {
    description = "Grafana NodePort from Internet"
    from_port   = 31000
    to_port     = 31000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound to Internet for downloading images/packages
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "clixx-k8s-node-sg" })

  depends_on = [aws_security_group.bastion_sg, aws_security_group.k8s_alb_sg]
}

# RDS Security Group - allows MySQL from K8s nodes
resource "aws_security_group" "rds_sg" {
  name        = "clixx-rds-sg"
  description = "Security Group for RDS"
  vpc_id      = aws_vpc.main.id

  # Allow from K8s node security group
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.k8s_sg.id]
    description     = "MySQL access from K8s nodes"
  }
  
  # Allow from private app subnets (CIDR-based as backup)
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.private_app_subnet_cidrs
    description = "MySQL access from private app subnets"
  }

  # Allow from VPC CIDR
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "MySQL access from entire VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "clixx-rds-sg" })

  depends_on = [aws_security_group.k8s_sg]
}

# Oracle DB Security Group
resource "aws_security_group" "oracle_sg" {
  name        = "clixx-oracle-sg"
  description = "Security Group for Oracle DB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [aws_security_group.k8s_sg.id]
    description     = "Oracle access from K8s nodes"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "clixx-oracle-sg" }, local.custom_tags)

  depends_on = [aws_vpc.main, aws_security_group.k8s_sg]
}

# ========================================
# DATABASE RESOURCES
# ========================================

# Update Database Subnet Group to use all DB subnets
resource "aws_db_subnet_group" "clixx_db_subnet_group" {
  name        = "clixx-db-subnet-group"
  description = "Subnet group for Clixx RDS instance"
  subnet_ids  = aws_subnet.private_db[*].id

  tags = merge(
    var.common_tags,
    {
      Name = "clixx-db-subnet-group"
    },
    local.custom_tags
  )

  depends_on = [aws_subnet.private_db]
}

# Create Java DB subnet group
resource "aws_db_subnet_group" "java_db_subnet_group" {
  name        = "java-db-subnet-group"
  description = "Subnet group for Java DB instance"
  subnet_ids  = aws_subnet.private_java_db[*].id

  tags = merge(
    var.common_tags,
    {
      Name = "java-db-subnet-group"
    },
    local.custom_tags
  )

  depends_on = [aws_subnet.private_java_db]
}

# MySQL parameter group to match the RDS snapshot
resource "aws_db_parameter_group" "mysql80" {
  name        = "clixx-mysql80"
  family      = "mysql8.0"
  description = "Custom parameter group for MySQL 8.0"
  
  tags = merge(
    var.common_tags,
    {
      Name = "clixx-mysql80-parameter-group"
    },
    local.custom_tags
  )
}

# RDS Instance - restored from snapshot
resource "aws_db_instance" "clixx_db" {
  identifier             = "wordpressdbclixxjenkins"
  instance_class         = var.db_instance_class
  snapshot_identifier    = var.db_snapshot_identifier
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.clixx_db_subnet_group.name
  multi_az               = true  
  publicly_accessible    = false
  skip_final_snapshot    = true  
  storage_encrypted      = true
  apply_immediately      = true  

  auto_minor_version_upgrade = false
  
  backup_retention_period = 0
  backup_window           = null
  maintenance_window      = "Mon:00:00-Mon:03:00"
  
  parameter_group_name = aws_db_parameter_group.mysql80.name
  
  tags = merge(
    var.common_tags,
    {
      Name = "wordpressdbclixxjenkins"
    },
    local.custom_tags
  )

  lifecycle {
    ignore_changes = [
      snapshot_identifier,
      engine_version,
      backup_retention_period,
      backup_window,
      maintenance_window
    ]
  }

  depends_on = [
    aws_db_subnet_group.clixx_db_subnet_group,
    aws_security_group.rds_sg
  ]
}

# ========================================
# LOAD BALANCER RESOURCES 
# ========================================

# Application Load Balancer for Kubernetes
resource "aws_lb" "k8s_alb" {
  name               = "clixx-k8s-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.k8s_alb_sg.id]
  subnets            = aws_subnet.public[*].id

  tags = merge(var.common_tags, { Name = "clixx-k8s-alb" })

  depends_on = [aws_internet_gateway.igw]
}

# Target Group for NodePort 30000 
resource "aws_lb_target_group" "k8s_tg" {
  name     = "clixx-k8s-tg"
  port     = 30000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(var.common_tags, { Name = "clixx-k8s-tg" })
}

# Target Group for Grafana NodePort 31000
resource "aws_lb_target_group" "grafana_tg" {
  name     = "clixx-grafana-tg"
  port     = 31000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/api/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(var.common_tags, { Name = "clixx-grafana-tg" })
}

# Attach Worker Nodes to Target Group
resource "aws_lb_target_group_attachment" "k8s_workers_attachment" {
  count            = var.k8s_worker_count
  target_group_arn = aws_lb_target_group.k8s_tg.arn
  target_id        = aws_instance.k8s_workers[count.index].id
  port             = 30000

  depends_on = [aws_instance.k8s_workers]
}

# Attach Worker Nodes to Grafana Target Group
resource "aws_lb_target_group_attachment" "grafana_workers_attachment" {
  count            = var.k8s_worker_count
  target_group_arn = aws_lb_target_group.grafana_tg.arn
  target_id        = aws_instance.k8s_workers[count.index].id
  port             = 31000

  depends_on = [aws_instance.k8s_workers]
}

# HTTP Listener
resource "aws_lb_listener" "k8s_http" {
  load_balancer_arn = aws_lb.k8s_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_tg.arn
  }
}

# HTTPS Listener - Update to use forward action with conditions
resource "aws_lb_listener" "k8s_https" {
  load_balancer_arn = aws_lb.k8s_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.clixx_cert.arn

  # Default action goes to the app
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_tg.arn
  }
}

# Listener Rule for Grafana (host-based routing)
resource "aws_lb_listener_rule" "grafana_rule" {
  listener_arn = aws_lb_listener.k8s_https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }

  condition {
    host_header {
      values = ["grafana.stack-claye.com"]
    }
  }
}

# Route53 Record - Points ecs.stack-claye.com to K8s ALB
resource "aws_route53_record" "k8s_record" {
  zone_id = data.aws_route53_zone.clixx_zone.zone_id
  name    = "ecs.stack-claye.com"
  type    = "A"

  alias {
    name                   = aws_lb.k8s_alb.dns_name
    zone_id                = aws_lb.k8s_alb.zone_id
    evaluate_target_health = true
  }
}

# Route53 Record - Points grafana.stack-claye.com to same ALB
resource "aws_route53_record" "grafana_record" {
  zone_id = data.aws_route53_zone.clixx_zone.zone_id
  name    = "grafana.stack-claye.com"
  type    = "A"

  alias {
    name                   = aws_lb.k8s_alb.dns_name
    zone_id                = aws_lb.k8s_alb.zone_id
    evaluate_target_health = true
  }
}

# ========================================
# SSM PARAMETERS
# ========================================

# SSM Parameter Store for database credentials
resource "aws_ssm_parameter" "db_name" {
  name  = "/clixx/db_name"
  type  = "String"
  value = aws_db_instance.clixx_db.db_name
}

resource "aws_ssm_parameter" "db_user" {
  name  = "/clixx/db_user"
  type  = "String"
  value = var.db_user
}

resource "aws_ssm_parameter" "db_password" {
  name      = "/clixx/db_password"
  type      = "SecureString"
  value     = var.db_password
}

resource "aws_ssm_parameter" "rds_endpoint" {
  name      = "/clixx/RDS_ENDPOINT"
  type      = "String"
  value     = aws_db_instance.clixx_db.address

  depends_on = [aws_db_instance.clixx_db]
}

# Updated to reference K8s ALB
resource "aws_ssm_parameter" "lb_dns" {
  name      = "/clixx/lb_dns"
  type      = "String"
  value     = aws_lb.k8s_alb.dns_name

  tags = merge(
    var.common_tags,
    {
      Name = "clixx-k8s-alb-dns-parameter"
    },
    local.custom_tags
  )
  
  depends_on = [aws_lb.k8s_alb]
}

resource "aws_ssm_parameter" "hosted_zone_name" {
  name  = "/clixx/hosted_zone_name"
  type  = "String"
  value = var.hosted_zone_name
}

resource "aws_ssm_parameter" "hosted_zone_record" {
  name  = "/clixx/hosted_zone_record"
  type  = "String"
  value = var.create_dns_record ? var.hosted_zone_record_name : ""
}

resource "aws_ssm_parameter" "hosted_zone_id" {
  name  = "/clixx/hosted_zone_id"
  type  = "String"
  value = var.create_dns_record ? data.aws_route53_zone.clixx_zone.zone_id : ""
}

resource "aws_ssm_parameter" "wp_admin_user" {
  name  = "/clixx/wp_admin_user"
  type  = "String"
  value = var.wp_admin_user
}

resource "aws_ssm_parameter" "wp_admin_password" {
  name      = "/clixx/wp_admin_password"
  type      = "SecureString"
  value     = var.wp_admin_password
}

resource "aws_ssm_parameter" "wp_admin_email" {
  name  = "/clixx/wp_admin_email"
  type  = "String"
  value = var.wp_admin_email
}

# K8s-specific SSM parameters
resource "aws_ssm_parameter" "k8s_master_ip" {
  name      = "/clixx/k8s_master_ip"
  type      = "String"
  value     = aws_instance.k8s_master.private_ip

  tags = merge(var.common_tags, { Name = "clixx-k8s-master-ip" })
  
  depends_on = [aws_instance.k8s_master]
}

resource "aws_ssm_parameter" "private_subnet_id" {
  name      = "/clixx/private_subnet_id"
  type      = "String"
  value     = aws_subnet.private_app[0].id
  
  tags = merge(
    var.common_tags,
    {
      Name = "clixx-private-subnet-id-parameter"
    },
    local.custom_tags
  )
}

resource "aws_ssm_parameter" "k8s_security_group_id" {
  name      = "/clixx/k8s_security_group_id"
  type      = "String"
  value     = aws_security_group.k8s_sg.id
  
  tags = merge(
    var.common_tags,
    {
      Name = "clixx-k8s-sg-id-parameter"
    },
    local.custom_tags
  )
}