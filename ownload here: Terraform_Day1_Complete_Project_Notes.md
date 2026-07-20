# Terraform AWS EC2 Project (Day 1)

> Hands-on notes covering everything built from scratch.

# Objective

Provision AWS infrastructure using Terraform that:
- Creates a custom VPC
- Creates a Public Subnet
- Attaches an Internet Gateway
- Configures a Route Table
- Creates a Security Group
- Registers an AWS Key Pair
- Launches an EC2 instance
- Installs Docker automatically using `user_data`

---

# Project Structure

```text
terraform-ec2/
├── versions.tf
├── provider.tf
├── variables.tf
├── vpc.tf
├── security-group.tf
├── keypair.tf
├── ec2.tf
├── userdata.sh
└── outputs.tf
```

---

# 1. versions.tf

Purpose:
- Lock Terraform CLI version.
- Lock AWS provider version.

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

Explanation:
- `terraform {}` configures Terraform itself.
- `required_version` avoids incompatible Terraform versions.
- `required_providers` downloads the AWS provider plugin.

---

# 2. provider.tf

Purpose:
Connect Terraform to AWS.

```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
```

Explanation:
- Provider tells Terraform which cloud to use.
- Region comes from a variable.
- Default tags are automatically applied to all supported AWS resources.

---

# 3. variables.tf

Purpose:
Avoid hardcoding values and make the project reusable.

Important variables:
- aws_region
- project_name
- environment
- vpc_cidr
- public_subnet_cidr
- availability_zone
- ami_id (prompted)
- instance_type (prompted)
- instance_count

Why prompt for AMI and instance type?
The coach wanted the user to provide them during deployment rather than hardcoding.

---

# 4. VPC Architecture

```text
Internet
   │
Internet Gateway
   │
Route Table
   │
Public Subnet
   │
EC2
   │
Inside Custom VPC
```

Resources:
- aws_vpc
- aws_internet_gateway
- aws_subnet
- aws_route_table
- aws_route_table_association

Important concepts:
- CIDR defines the network range.
- `map_public_ip_on_launch = true` assigns public IPs.
- `0.0.0.0/0` means all destinations.

Terraform builds dependencies automatically because resources reference each other.

---

# 5. security-group.tf

Purpose:
Acts as the EC2 firewall.

Ingress:
- TCP 22 (SSH)
- TCP 80 (HTTP)
- TCP 9000 (Future SonarQube)

Egress:
- Allow all outbound traffic.

Concept:
Security Groups are stateful.

---

# 6. keypair.tf

Purpose:
Upload the local SSH public key to AWS.

```hcl
resource "aws_key_pair" "terraform_key" {
  key_name   = "terrra-key-ec2"
  public_key = file("${path.module}/terrra-key-ec2.pub")
}
```

Explanation:
- Only the `.pub` key is uploaded.
- The private key always stays on your laptop.
- EC2 receives the public key during launch.

---

# 7. ec2.tf

Purpose:
Launch EC2.

Important arguments:
- count
- ami
- instance_type
- subnet_id
- vpc_security_group_ids
- key_name
- associate_public_ip_address
- user_data

Execution flow:

```text
terraform apply
      │
      ▼
AWS API
      ▼
EC2 Created
      ▼
Ubuntu Boots
      ▼
Cloud-init
      ▼
userdata.sh
```

Why use `count`?
One resource block can create multiple EC2 instances.

---

# 8. userdata.sh

Purpose:
Automatically configure the server.

Recommended script:

```bash
#!/bin/bash
set -e

exec > >(tee /var/log/user-data.log) 2>&1

echo "Starting user-data"

apt-get update -y

if ! command -v docker >/dev/null 2>&1; then
  apt-get install -y docker.io
  systemctl enable docker
  systemctl start docker
  usermod -aG docker ubuntu
fi

docker --version

echo "Completed user-data"
```

Explanation:
- `set -e` exits if a command fails.
- Logging helps troubleshooting.
- Docker is installed only if missing.
- Docker service starts automatically after reboot.

---

# 9. outputs.tf

Purpose:
Display useful values after deployment.

Outputs:
- Instance ID
- Public IP
- Public DNS
- VPC ID
- Public Subnet ID
- Security Group ID

When `count` is used, outputs use `[*]` to return values for all instances.

---

# Terraform Commands

```bash
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

Purpose:
- fmt → format code
- init → download providers
- validate → syntax check
- plan → preview changes
- apply → create infrastructure
- destroy → remove infrastructure

---

# Overall Execution Order

```text
Terraform
   │
Read Configuration
   │
Dependency Graph
   │
Create VPC
   │
Create Internet Gateway
   │
Create Public Subnet
   │
Create Route Table
   │
Associate Route Table
   │
Create Security Group
   │
Create Key Pair
   │
Launch EC2
   │
Run userdata.sh
   │
Docker Installed
```

---

# Best Practices Learned

- Use variables instead of hardcoding.
- Keep shell scripts outside Terraform files.
- Use `path.module` for local file references.
- Add logging to `user_data`.
- Use tags on all resources.
- Use outputs to expose important values.
- Build networking before compute.

---

# Next Phase

- Terraform Modules
- Remote State (S3 + DynamoDB)
- Multi-environment
- Load Balancer
- Auto Scaling
- EKS
- CI/CD
