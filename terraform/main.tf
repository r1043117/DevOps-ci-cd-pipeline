# VARIABLES - These are like function parameters, they let you customize your infrastructure
# You'll set the actual values in terraform.tfvars

variable "aws_region" {
  description = "The AWS region where we'll create the VM"
  type        = string
  default     = "eu-west-1"  # Ireland region - you can change this
}

variable "ssh_key_name" {
  description = "The name of the SSH key pair in AWS to access the VM"
  type        = string
  default     = "klinkr-key"  # Your existing SSH key
}

# ADDED: Variable to control SSH access - set to your home IP for better security
variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the VM (e.g., 'xxx.xxx.xxx.xxx/32' for single IP)"
  type        = string
  default     = "0.0.0.0/0"  # Default: allow from anywhere (for lab use)
                              # To restrict: change to your home IP like "1.2.3.4/32"
}

# DATA SOURCE - This fetches the latest Debian 12 image from AWS
# AWS maintains official Debian images, this finds the newest one
data "aws_ami" "debian12" {
  most_recent = true  # Get the latest version
  owners      = ["136693071363"]  # Official Debian AWS account ID

  # Filter to find exactly Debian 12 (bookworm) for x86_64 architecture
  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]  # The * means "any build date"
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]  # Hardware Virtual Machine (modern virtualization)
  }
}

# SECURITY GROUP - This is like a firewall for your VM
# It controls what network traffic is allowed in and out
resource "aws_security_group" "app_server_sg" {
  name        = "app-server-sg"
  description = "Security group for App Server (Flask application)"

  # Ingress = incoming traffic TO your VM
  ingress {
    description = "SSH from anywhere"
    from_port   = 22        # SSH uses port 22
    to_port     = 22
    protocol    = "tcp"     # SSH uses TCP protocol
    cidr_blocks = ["0.0.0.0/0"]  # Allow from any IP (0.0.0.0/0 means "the entire internet")
                                  # For better security, replace with your IP like ["1.2.3.4/32"]
  }

  # ADDED: HTTP port for web traffic (Flask app will use this)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80        # HTTP uses port 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow web traffic from any IP
  }

  # ADDED: HTTPS port for secure web traffic
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443       # HTTPS uses port 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow secure web traffic from any IP
  }

  # Flask application port (default Flask development server port)
  # NOTE: Later we'll move Flask behind nginx on port 80, but for now we use direct access
  ingress {
    description = "Flask app from anywhere"
    from_port   = 5000      # Flask default port
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow Flask access from any IP
  }

  # Egress = outgoing traffic FROM your VM
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0         # 0 means all ports
    to_port     = 0
    protocol    = "-1"      # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]  # Allow to any IP
  }

  tags = {
    Name        = "app-server-sg"
    Environment = "lab"                # ADDED: Identifies this as lab/test environment
    Purpose     = "app-server"         # ADDED: What this security group is for
    ManagedBy   = "terraform"          # ADDED: Shows this is managed by Terraform
  }
}

# EC2 INSTANCE - This is your actual virtual machine!
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.debian12.id  # Use the Debian 12 image we found above
  instance_type = "t3.micro"                 # VM size: 2 vCPUs, 1GB RAM (free tier eligible)

  key_name      = var.ssh_key_name          # SSH key to access the VM

  # Attach the security group we created above
  vpc_security_group_ids = [aws_security_group.app_server_sg.id]

  # Root volume (disk) configuration
  root_block_device {
    volume_size = 20      # CHANGED: 20 GB disk for Docker images (was 8 GB, free tier allows up to 30GB)
    volume_type = "gp3"   # General Purpose SSD v3 (good performance, cost-effective)
  }

  tags = {
    Name        = "app-server"         # This name appears in the AWS console
    Environment = "lab"                # ADDED: Identifies this as lab/test environment
    Purpose     = "flask-app-server"   # ADDED: Flask app server with Docker and Git
    ManagedBy   = "terraform"          # ADDED: Shows this is managed by Terraform
    OS          = "debian-12"          # ADDED: Operating system for easy identification
  }
}
