# Project Architecture

> **Project:** Terraform AWS Infrastructure using Remote Backend, Modular Architecture, and Multi-Environment Workspaces

---

# Table of Contents

1. Introduction
2. Why This Project?
3. Project Goals
4. Technologies Used
5. High-Level Architecture
6. Project Directory Structure
7. Project Execution Flow
8. Architecture Deep Dive
9. Terraform Component Relationships
10. AWS Infrastructure Overview
11. Infrastructure Dependency Flow
12. Environment Strategy
13. Backend Architecture
14. State Management Overview
15. Module Architecture
16. Resource Creation Flow
17. Production Best Practices Used
18. Lessons Learned
19. Architecture Interview Questions
20. Summary

---

# 1. Introduction

Infrastructure provisioning has traditionally been a manual process. Engineers logged into cloud consoles, clicked through dozens of configuration pages, and repeated the same tasks for every environment.

This approach introduced several problems:

- Manual errors
- Configuration drift
- Lack of documentation
- Difficult disaster recovery
- Slow deployments
- Inconsistent environments

Infrastructure as Code (IaC) solves these challenges by describing infrastructure in code. Terraform is one of the most widely used IaC tools because it is cloud-agnostic, declarative, and supports modular reusable infrastructure.

This project demonstrates how to build a production-style AWS environment using Terraform while following industry best practices.

---

# 2. Why This Project?

This project was created to simulate how infrastructure is managed in a real DevOps team.

Instead of placing all Terraform resources in a single file, the project follows a modular architecture and uses a remote backend for collaboration.

The project demonstrates:

- Infrastructure as Code
- Modular design
- Multi-environment deployments
- Remote state management
- State locking
- AWS networking
- Compute provisioning
- Secure resource management

---

# 3. Project Goals

The primary objectives of this project are:

### Functional Goals

- Provision AWS infrastructure automatically
- Create a reusable VPC
- Launch EC2 instances
- Configure Security Groups
- Manage SSH Key Pairs
- Support multiple environments

### DevOps Goals

- Store Terraform state remotely
- Prevent state corruption
- Enable team collaboration
- Organize reusable modules
- Follow production-ready practices

### Learning Goals

By completing this project, you will understand:

- Terraform architecture
- Backend bootstrapping
- State management
- Workspace management
- Resource dependencies
- Module design
- AWS networking

---

# 4. Technologies Used

| Technology | Purpose |
|------------|---------|
| Terraform | Infrastructure as Code |
| AWS EC2 | Compute |
| AWS VPC | Networking |
| AWS S3 | Remote State Storage |
| DynamoDB | State Locking |
| AWS Security Groups | Firewall |
| AWS Key Pair | SSH Authentication |
| Git | Version Control |
| GitHub | Source Code Repository |

---

# 5. High-Level Architecture

```
                   Developer
                        │
                        │
                terraform apply
                        │
                        ▼
              Terraform CLI Engine
                        │
         ┌──────────────┴──────────────┐
         │                             │
         ▼                             ▼
 Remote Backend                    Provider
   (Amazon S3)                    AWS Provider
         │                             │
         ▼                             ▼
 DynamoDB Lock                 AWS API Calls
         │                             │
         └──────────────┬──────────────┘
                        ▼
                Terraform Modules
                        │
     ┌──────────┬────────┬─────────┬─────────┐
     ▼          ▼        ▼         ▼
    VPC     Security   KeyPair     EC2
              Group
```

---

# 6. Project Directory Structure

```
terraform-megha-project/

├── backend/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│
├── infra-app/
│   ├── backend.tf
│   ├── provider.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   └── versions.tf
│
├── modules/
│   ├── ec2/
│   ├── keypair/
│   ├── security-group/
│   └── vpc/
│
└── docs/
```

Each folder has a specific responsibility.

### backend/

Responsible for creating the Terraform backend.

Creates:

- S3 Bucket
- DynamoDB Table

This folder is executed only once.

---

### infra-app/

Contains the actual infrastructure.

This folder provisions:

- VPC
- Subnet
- Security Group
- Key Pair
- EC2

---

### modules/

Reusable infrastructure components.

Instead of repeating Terraform code, each resource is isolated into a reusable module.

Advantages:

- Easy maintenance
- Better readability
- Reusability
- Smaller codebase
- Easier debugging

---

# 7. Project Execution Flow

```
Write Terraform Code
        │
        ▼
terraform fmt
        │
        ▼
terraform validate
        │
        ▼
terraform init
        │
        ▼
terraform plan
        │
        ▼
terraform apply
        │
        ▼
AWS Infrastructure Created
        │
        ▼
terraform.tfstate updated
```

Every command has a different purpose.

During this project we used all of them multiple times.

Later chapters explain each command in detail.

---

# 8. Architecture Deep Dive

This project is divided into two logical layers.

## Layer 1 — Backend Infrastructure

Purpose:

Create the infrastructure required to store Terraform state.

Resources:

- S3 Bucket
- Versioning
- Encryption
- Public Access Block
- DynamoDB Lock Table

This layer must exist before deploying any application infrastructure.

---

## Layer 2 — Application Infrastructure

Uses the backend created in Layer 1.

Creates:

- VPC
- Subnet
- Internet Gateway
- Route Table
- Route Table Association
- Security Group
- Key Pair
- EC2

---

# 9. Terraform Component Relationships

```
main.tf

↓

Calls Modules

↓

Modules Create Resources

↓

Resources Call AWS APIs

↓

AWS Creates Infrastructure

↓

Terraform Updates State

↓

State Stored in S3

↓

Lock Removed from DynamoDB
```

---

# 10. AWS Infrastructure Overview

This project provisions:

## Networking

- One VPC
- One Public Subnet
- One Internet Gateway
- One Route Table
- One Route Table Association

---

## Security

- One Security Group
- SSH Port (22)
- HTTP Port (80)

---

## Compute

- Ubuntu EC2
- t3.micro
- Public IP
- User Data Bootstrap

---

## Backend

- S3 Bucket
- DynamoDB Table

---

# 11. Infrastructure Dependency Flow

Terraform automatically determines resource dependencies.

Example:

```
VPC

↓

Subnet

↓

Internet Gateway

↓

Route Table

↓

Security Group

↓

EC2
```

Terraform creates resources in dependency order.

This is why you observed during `terraform apply`:

1. VPC
2. Internet Gateway
3. Security Group
4. Subnet
5. Route Table
6. Route Table Association
7. EC2

---

# 12. Environment Strategy

The project supports multiple isolated environments.

- Development
- Stage
- Production

Each environment has:

- Independent state
- Independent infrastructure
- Independent lifecycle

Terraform Workspaces provide this isolation.

Later chapters explain this in detail.

---

# 13. Backend Architecture

Instead of storing state locally, this project stores state in Amazon S3.

Benefits:

- Shared state
- Team collaboration
- Backup
- Version history
- Recovery

DynamoDB prevents multiple engineers from modifying state simultaneously.

---

# 14. State Management Overview

Terraform always compares:

Desired Configuration

vs

Current State

Only the required changes are executed.

Without state, Terraform cannot determine what already exists.

---

# 15. Module Architecture

This project follows modular design.

```
Root Module

↓

VPC Module

↓

Security Group Module

↓

Key Pair Module

↓

EC2 Module
```

Each module has:

- variables.tf
- main.tf
- outputs.tf

This makes the code reusable across environments.

---

# 16. Resource Creation Flow

When `terraform apply` is executed:

1. Provider authentication
2. Backend lock acquired
3. State downloaded
4. AWS queried
5. Plan generated
6. Resources created
7. Outputs generated
8. State uploaded
9. Lock released

---

# 17. Production Best Practices Used

Throughout this project we implemented several production practices.

- Modular Terraform
- Remote Backend
- State Locking
- Workspace Isolation
- Resource Tagging
- Encrypted State
- Versioned State
- Public Access Block
- Dynamic AMI Lookup
- Outputs
- Variable Files

Each of these topics is covered individually in later chapters.

---

# 18. Lessons Learned

While building this project, several real-world issues were encountered.

Examples include:

- Backend initialization errors
- Missing state files
- Workspace confusion
- Backend reconfiguration
- Manual deletion causing state drift
- Bucket versioning preventing deletion
- S3 object version cleanup
- AWS region configuration issues

Every issue will be documented in the Troubleshooting Guide with:

- Root Cause
- Symptoms
- Resolution
- Prevention

---

# 19. Architecture Interview Questions

### Beginner

1. What is Infrastructure as Code?
2. Why Terraform?
3. What is a module?
4. Why use AWS VPC?
5. Why create a Security Group?

### Intermediate

1. Explain the architecture of this project.
2. Why separate backend and application infrastructure?
3. How does Terraform determine resource order?
4. What are Terraform dependencies?
5. Why modularize infrastructure?

### Advanced

1. How would you scale this architecture for multiple AWS accounts?
2. How would you introduce CI/CD?
3. How would you secure secrets?
4. How would you implement private subnets and NAT Gateways?
5. How would you extend this architecture for EKS?

---

# 20. Summary

This project demonstrates a production-inspired Terraform architecture using reusable modules, remote state management, environment isolation, and AWS networking best practices.

By completing this project, you gain practical experience with Infrastructure as Code, remote backend configuration, Terraform state management, AWS resource provisioning, and production-oriented project organization.

---

## Next Chapter

➡️ **02-Terraform-Fundamentals.md**

In the next chapter we will answer:

- What exactly is Terraform?
- Why was Terraform created?
- How does Terraform work internally?
- What happens during `terraform init`, `plan`, `apply`, and `destroy`?
- What are providers, resources, data sources, variables, outputs, and state?
- How Terraform builds the dependency graph before creating resources.