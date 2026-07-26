# Terraform Fundamentals

> Before writing a single line of Terraform code, every DevOps engineer should understand **why Terraform exists, how it works internally, and what happens behind every command**.

This chapter explains Terraform from the ground up using our project as the reference implementation.

---

# Table of Contents

1. What is Infrastructure as Code (IaC)?
2. Problems with Manual Infrastructure
3. What is Terraform?
4. Why Terraform Was Created
5. How Terraform Works
6. Terraform Architecture
7. Terraform Workflow
8. Core Building Blocks
9. Providers
10. Resources
11. Data Sources
12. Variables
13. Outputs
14. Local Values
15. Modules
16. Dependency Graph
17. State File
18. Terraform Lifecycle Commands
19. Internal Working of Terraform
20. Advantages & Limitations
21. Common Beginner Mistakes
22. Interview Questions
23. Summary

---

# 1. What is Infrastructure as Code (IaC)?

Infrastructure as Code (IaC) is the practice of managing and provisioning infrastructure using code instead of manually creating resources through a web console.

Instead of logging into AWS and clicking:

- Create VPC
- Create Subnet
- Create EC2
- Create Security Group

we define everything inside code.

Example:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-xxxxxxxx"
  instance_type = "t3.micro"
}
```

Terraform reads this code and creates the infrastructure automatically.

---

# 2. Problems with Manual Infrastructure

Imagine a company with:

- Development Environment
- Testing Environment
- Production Environment

Suppose each environment contains:

- 3 VPCs
- 20 EC2 instances
- 12 Security Groups
- Load Balancers
- IAM Roles
- S3 Buckets

Creating these manually introduces many problems.

## Problem 1 – Human Error

An engineer may accidentally:

- Open port 22 to everyone.
- Launch the wrong EC2 instance type.
- Choose the wrong subnet.
- Forget to enable encryption.

Small mistakes can lead to security issues or outages.

---

## Problem 2 – No Version Control

If infrastructure is created manually, there is no history of:

- Who made the change?
- When was it changed?
- Why was it changed?

With Terraform, all changes are tracked in Git.

---

## Problem 3 – Inconsistent Environments

Development might have:

```
t3.micro
```

Production might accidentally have:

```
t2.nano
```

This inconsistency causes application issues.

Terraform ensures environments are created from the same code.

---

## Problem 4 – Difficult Disaster Recovery

If someone deletes a VPC manually, rebuilding it from memory is difficult.

Terraform can recreate the infrastructure from code.

---

# 3. What is Terraform?

Terraform is an open-source Infrastructure as Code (IaC) tool developed by HashiCorp.

It allows engineers to define cloud infrastructure using declarative configuration files.

Terraform supports many providers, including:

- AWS
- Azure
- Google Cloud
- Kubernetes
- VMware
- GitHub
- Cloudflare

One language can manage multiple platforms.

---

# 4. Why Terraform Was Created

Before Terraform, engineers often used cloud-specific tools.

Examples:

AWS → CloudFormation

Azure → ARM Templates

Google → Deployment Manager

Each tool worked only for its own cloud.

Terraform introduced a unified way to manage infrastructure across different providers.

This made it easier for organizations using multiple cloud platforms.

---

# 5. How Terraform Works

Terraform follows a declarative model.

You define the desired state of your infrastructure.

Terraform compares the desired state with the current state.

It then determines the changes needed to make them match.

The workflow looks like this:

```
Terraform Code
       │
       ▼
 Desired State
       │
       ▼
Compare with Current State
       │
       ▼
Generate Execution Plan
       │
       ▼
Apply Changes
       │
       ▼
Infrastructure Updated
```

Terraform decides:

- What needs to be created?
- What needs to be modified?
- What needs to be destroyed?

---

# 6. Terraform Architecture

```
              Developer

                  │

          Terraform CLI

                  │

        Parse HCL Configuration

                  │

        Build Dependency Graph

                  │

         Load Current State

                  │

 Compare Desired vs Current State

                  │

          Generate Plan

                  │

          Call Provider

                  │

              AWS API

                  │

         Infrastructure Created

                  │

         Update State File
```

---

# 7. Terraform Workflow

Every Terraform project follows this lifecycle.

```
Write Code

↓

terraform fmt

↓

terraform validate

↓

terraform init

↓

terraform plan

↓

terraform apply

↓

terraform destroy
```

Each command has a different responsibility.

---

# 8. Core Building Blocks

Terraform is built using several components.

- Providers
- Resources
- Data Sources
- Variables
- Outputs
- Modules
- State
- Backend

Each one plays a different role.

---

# 9. Providers

A provider acts as the bridge between Terraform and an external platform.

Example:

```hcl
provider "aws" {
  region = "ap-south-1"
}
```

The AWS provider translates Terraform code into AWS API calls.

Without a provider, Terraform has no way to communicate with AWS.

---

# 10. Resources

Resources define infrastructure that Terraform should create.

Example:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

This tells Terraform:

"Create a VPC."

Resources are managed by Terraform.

Terraform tracks them in the state file.

---

# 11. Data Sources

Sometimes infrastructure already exists.

Instead of creating it again, Terraform can read it.

Example:

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
}
```

This retrieves the latest Ubuntu AMI.

In our project, we used a data source to avoid hardcoding the AMI ID.

---

# 12. Variables

Variables make Terraform reusable.

Instead of writing:

```
instance_type = "t3.micro"
```

we can write:

```hcl
instance_type = var.instance_type
```

Now the same code works for multiple environments.

---

# 13. Outputs

Outputs display important values after deployment.

Example:

```hcl
output "public_ip" {
  value = aws_instance.web.public_ip
}
```

After `terraform apply`, Terraform prints the public IP.

In our project we used outputs for:

- VPC ID
- Public IP
- Private IP
- Key Name
- Security Group ID

---

# 14. Local Values

Locals help avoid repeating values.

Example:

```hcl
locals {
  project_name = "terraform-megha-project"
}
```

Instead of typing the project name many times, we reference:

```hcl
local.project_name
```

---

# 15. Modules

Modules are reusable collections of Terraform code.

Our project contains modules for:

- VPC
- EC2
- Key Pair
- Security Group

Benefits:

- Reusability
- Smaller code
- Easier maintenance
- Cleaner architecture

---

# 16. Dependency Graph

Terraform automatically builds a dependency graph.

Example:

```
VPC

↓

Subnet

↓

Security Group

↓

EC2
```

Terraform understands that an EC2 instance cannot be created until the VPC, subnet, and security group exist.

This is why resources are created in the correct order during `terraform apply`.

---

# 17. State File

Terraform stores information about managed infrastructure in the state file.

The state file answers questions like:

- Which resources exist?
- What are their IDs?
- What values were assigned?
- What outputs are available?

Without the state file, Terraform cannot determine the current state of your infrastructure.

Later chapters will explain local state, remote state, state locking, and state migration in detail.

---

# 18. Terraform Lifecycle Commands

### terraform fmt

Formats Terraform code according to standard style.

### terraform validate

Checks the syntax and validates configuration.

### terraform init

Downloads providers and initializes the backend.

### terraform plan

Shows what Terraform intends to change.

### terraform apply

Creates or updates infrastructure.

### terraform destroy

Deletes managed infrastructure.

---

# 19. Internal Working of Terraform

When you run:

```bash
terraform apply
```

Terraform performs these steps:

1. Read all `.tf` files.
2. Parse HCL configuration.
3. Load provider plugins.
4. Download current state.
5. Refresh resource information.
6. Build dependency graph.
7. Compare desired state with current state.
8. Generate an execution plan.
9. Ask for user approval.
10. Create, update, or delete resources.
11. Save the updated state.

---

# 20. Advantages & Limitations

## Advantages

- Infrastructure as Code
- Version Control
- Reproducible Deployments
- Multi-cloud Support
- Declarative Syntax
- Automation
- Collaboration
- Modular Design

## Limitations

- State management must be handled carefully.
- Manual changes can cause state drift.
- Sensitive information may exist in state files.
- Backend configuration requires planning.

---

# 21. Common Beginner Mistakes

- Hardcoding AMI IDs instead of using data sources.
- Storing state locally for team projects.
- Ignoring `terraform plan`.
- Editing the state file manually.
- Not using modules.
- Forgetting to commit `.terraform.lock.hcl`.
- Running `terraform apply` without understanding the execution plan.

---

# 22. Interview Questions

## Beginner

1. What is Infrastructure as Code?
2. What is Terraform?
3. What is HCL?
4. What is a provider?
5. What is a resource?
6. What is a variable?
7. What is an output?

---

## Intermediate

1. Explain Terraform architecture.
2. Difference between resource and data source.
3. Explain Terraform state.
4. Why is `terraform plan` important?
5. What is dependency graph?

---

## Advanced

1. Explain Terraform's internal execution flow.
2. How does Terraform detect changes?
3. How does Terraform build a dependency graph?
4. Why is Terraform declarative?
5. How would you structure Terraform for a large enterprise?

---

# 23. Summary

Terraform is more than a provisioning tool—it is a complete Infrastructure as Code platform. By understanding providers, resources, modules, variables, state, and the Terraform lifecycle, you build the foundation required for advanced topics such as remote backends, state locking, workspaces, and production-grade infrastructure management.

---

## Next Chapter

➡️ **03-Project-Structure.md**

In the next chapter we will perform a complete walkthrough of our project directory. We will explain every folder, every Terraform file (`main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`, `provider.tf`, `versions.tf`, `backend.tf`, `terraform.tfvars`), why each file exists, how they interact, and how our project's modular architecture is organized.