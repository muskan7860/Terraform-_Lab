
# Terraform on AWS – Complete Project Documentation

## Overview
This document explains the complete Terraform project implemented on AWS using a production-style structure.

### Objectives
- Provision AWS infrastructure using Infrastructure as Code (IaC)
- Use reusable Terraform modules
- Store remote state in Amazon S3
- Protect state with DynamoDB state locking
- Separate environments using Terraform Workspaces (dev, stage, prod)

## Architecture

```text
Developer
   |
terraform init/plan/apply
   |
Terraform Core
   |
AWS Provider
   |
+-----------------------------+
| S3 Backend (Remote State)   |
| DynamoDB (State Locking)    |
+-----------------------------+
            |
            v
        AWS Resources
        ├── VPC
        ├── Subnet
        ├── Route Table
        ├── Internet Gateway
        ├── Security Group
        ├── EC2
        └── Key Pair
```

## Phase 1 – Backend

Why remote backend?
- Team collaboration
- Single source of truth
- Prevent state corruption
- Enable locking

### Backend configuration

```hcl
terraform {
  backend "s3" {}
}
```

Values supplied through backend configuration file.

## What happens during terraform init?

1. Reads backend block.
2. Downloads provider plugins.
3. Downloads modules.
4. Configures backend.
5. Connects to S3.
6. Reads state.
7. Configures workspace.

## State

Terraform state maps infrastructure to configuration.

Without state Terraform would recreate infrastructure every execution.

Commands:

```bash
terraform state list
terraform state show RESOURCE
terraform state pull
terraform state rm
```

## Workspaces

Environments:
- dev
- stage
- prod

Each workspace keeps an independent state file.

## Modules

Project contains reusable modules for:

- VPC
- Security Group
- EC2
- Key Pair

Benefits:
- Reuse
- Maintainability
- Consistency

## Troubleshooting Encountered

### Backend asked for bucket name

Cause:
Backend block contained values while backend config was incomplete.

Solution:

```bash
terraform init -reconfigure -backend-config=../backend/dev.hcl
```

### No state file found

Cause:
Workspace had empty remote state.

Diagnosis:

```bash
terraform workspace show
terraform state pull
```

### Workspace not found

Cause:
Workspace never created in backend.

Create:

```bash
terraform workspace new dev
```

### Destroy returned 0 resources

Reason:
Remote state was empty although AWS resources still existed.

### BucketNotEmpty error

Reason:
Versioned S3 bucket still contained state versions.

Solution:
Delete object versions first, then destroy bucket.

## Interview Questions

### What is Terraform State?

Answer:
Terraform State is a mapping database maintained by Terraform that stores metadata about deployed infrastructure so Terraform can determine what already exists and what must change.

### Why use S3 backend?

Answer:
To centralize state, enable collaboration, improve durability, and avoid local state conflicts.

### Why DynamoDB?

Answer:
To provide state locking so multiple engineers cannot modify the same infrastructure simultaneously.

### Why Modules?

Answer:
To improve reuse, readability, consistency, scalability, and maintenance.

### Difference between terraform plan and apply?

plan computes execution changes only.
apply executes those changes.

## Best Practices

- Never commit tfstate.
- Enable bucket versioning.
- Enable encryption.
- Use remote backend.
- Use modules.
- Keep environments isolated.
- Store secrets securely.
- Review plan before apply.

## Project Summary

This project provisions AWS infrastructure using reusable Terraform modules with an S3 remote backend, DynamoDB locking, and workspace-based environment separation. During implementation we configured backend initialization, migrated state, diagnosed workspace/state issues, handled manual resource drift, managed versioned S3 cleanup, and validated deployments across dev, stage, and prod environments.