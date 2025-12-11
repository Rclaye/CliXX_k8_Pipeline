# Bastion Host Configuration

# IAM Role and Policy for Bastion Host with SSM Access
resource "aws_iam_role" "bastion_role" {
  name = "clixx-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = merge(var.common_tags, { Name = "clixx-bastion-role" })
}

resource "aws_iam_role_policy_attachment" "bastion_ssm_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile for Bastion Host
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "clixx-bastion-profile"
  role = aws_iam_role.bastion_role.name
}

# Bastion Host Instance
resource "aws_instance" "bastion" {
  count                       = 1
  ami                         = var.bastion_ami_id != "" ? var.bastion_ami_id : var.k8s_ami_id
  instance_type               = var.bastion_instance_type
  subnet_id                   = aws_subnet.public[0].id
  key_name                    = var.bastion_key_name
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  tags = merge(var.common_tags, {
    Name = "clixx-bastion"
    Role = "bastion"
  })

  depends_on = [aws_internet_gateway.igw]

  user_data = <<-EOF
    #!/bin/bash
    # Update and install packages (Ubuntu-compatible)
    apt-get update -y
    apt-get install -y apache2 mysql-client php git unzip

    # Install AWS CLI
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -rf awscliv2.zip aws/

    # Enable Apache
    systemctl enable --now apache2
    echo "<h1>Clixx Retail - Bastion Host</h1>" > /var/www/html/index.html
    
    # Set up SSH configuration for easier private instance access
    mkdir -p /home/ubuntu/.ssh
    touch /home/ubuntu/.ssh/${var.private_instance_ssh_key_destination_filename_on_bastion}
    
    cat > /home/ubuntu/.ssh/config << 'SSHCONFIG'
    Host 10.*
      User ubuntu
      IdentityFile ~/.ssh/${var.private_instance_ssh_key_destination_filename_on_bastion}
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
    SSHCONFIG
    
    chown -R ubuntu:ubuntu /home/ubuntu/.ssh
    chmod 700 /home/ubuntu/.ssh
    chmod 600 /home/ubuntu/.ssh/config
  EOF
}