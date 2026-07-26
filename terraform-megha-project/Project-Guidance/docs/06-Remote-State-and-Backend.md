# Phase 6 - Terraform Remote State, S3 Backend & State Locking (Complete Deep Dive)

---

# Goal

In this phase, we moved Terraform state from the local machine to AWS S3 and implemented state locking using DynamoDB.

This transformed our Terraform project from a local development setup into a production-grade Infrastructure as Code (IaC) solution that supports team collaboration, prevents state corruption, and enables centralized infrastructure management.

---

# Why did we need a Remote Backend?

Initially, Terraform stored its state locally.

```
terraform.tfstate
```

This file existed only on one developer's laptop.

Problems with local state:

❌ Lost if laptop crashes

❌ Cannot be shared with team members

❌ Merge conflicts

❌ Multiple users can overwrite each other's changes

❌ Difficult to back up

❌ No locking mechanism

❌ Not suitable for production

---

# What is Terraform State?

Terraform State is a JSON file that stores information about every resource Terraform manages.

Terraform uses this file to understand:

- What resources exist
- Their IDs
- Their current configuration
- Their dependencies
- Outputs
- Metadata

Terraform NEVER queries AWS for every comparison.

Instead, it compares

```
Configuration (.tf)

↓

terraform.tfstate

↓

AWS Infrastructure
```

---

# Why is State Important?

Without state,

Terraform would not know

- which EC2 belongs to Terraform
- which VPC was created
- what needs updating
- what needs deleting

State is Terraform's memory.

---

# What does terraform.tfstate contain?

A simplified example:

```json
{
  "resources": [
    {
      "type": "aws_instance",
      "name": "ec2",
      "instances": [
        {
          "attributes": {
            "id": "i-123456789",
            "public_ip": "3.111.xxx.xxx",
            "private_ip": "10.0.1.89"
          }
        }
      ]
    }
  ]
}
```

---

# Why should we never edit terraform.tfstate manually?

Terraform expects this file to follow a strict format.

Manual editing can result in:

- State corruption
- Missing resources
- Duplicate resources
- Destroy failures
- Apply failures

Always use Terraform commands instead of editing the file.

---

# Local Backend

By default Terraform stores state locally.

```
terraform.tfstate
```

Advantages

✔ Simple

✔ Easy for learning

Disadvantages

✖ Not shared

✖ No locking

✖ Not production ready

---

# Remote Backend

A Remote Backend stores state in a remote location.

Examples

AWS S3

Azure Storage

Terraform Cloud

Google Cloud Storage

Consul

---

# Why did we choose S3?

AWS S3 provides

✔ Durable storage

✔ Highly available

✔ Versioning

✔ Encryption

✔ Easy integration

✔ Central storage

---

# Backend Architecture

```
Developer

↓

Terraform CLI

↓

S3 Backend

↓

terraform.tfstate

↓

AWS Infrastructure
```

---

# What is a Backend?

A Backend tells Terraform

"Where should I store my state?"

Example

```
terraform {

backend "s3" {}

}
```

Notice

No credentials

No bucket

No region

Everything is supplied externally.

---

# Why keep backend configuration empty?

We created

```
backend.tf
```

```
terraform {

backend "s3" {}

}
```

Why?

Because every environment has different backend settings.

Hardcoding backend information makes projects difficult to reuse.

---

# Environment Backend Files

We created

```
backend/

dev.hcl

stage.hcl

prod.hcl
```

Example

```
bucket = "terraform-megha-project-tfstate"

key = "dev/terraform.tfstate"

region = "ap-south-1"

dynamodb_table = "terraform-megha-project-locks"

encrypt = true
```

Each environment uses a different key.

---

# Why Different Keys?

Without different keys,

All environments write to the same state file.

That causes

State corruption

Resource overwrites

Unexpected destroy

Instead we use

```
dev/terraform.tfstate

stage/terraform.tfstate

prod/terraform.tfstate
```

Each environment has its own isolated state.

---

# Backend Initialization

We initialized Terraform using

```bash
terraform init \
-reconfigure \
-backend-config=../backend/dev.hcl
```

Terraform then

↓

Reads backend.tf

↓

Reads dev.hcl

↓

Connects to S3

↓

Downloads existing state

↓

Configures backend

---

# Why use -reconfigure?

Terraform caches backend information.

If backend configuration changes,

Terraform still remembers the old backend.

```
terraform init -reconfigure
```

forces Terraform to forget the cached backend and configure it again.

---

# What is State Locking?

Imagine

Developer A

↓

terraform apply

At the same time

Developer B

↓

terraform apply

Both update the same state.

Result

Corrupted state.

To prevent this,

Terraform locks the state.

---

# Why DynamoDB?

S3 cannot lock files.

S3 only stores files.

Terraform needs another service to coordinate access.

That service is

```
DynamoDB
```

---

# State Lock Flow

```
terraform apply

↓

Request Lock

↓

DynamoDB

↓

Lock Acquired

↓

Modify State

↓

Upload to S3

↓

Release Lock
```

---

# What happens if another engineer runs Apply?

Terraform checks DynamoDB.

Lock already exists.

Terraform waits.

Or returns

```
Error acquiring state lock
```

This prevents corruption.

---

# S3 Versioning

We enabled

```
Versioning
```

Why?

Every update creates a new version of the state.

Benefits

Accidental deletion

↓

Restore old version

State corruption

↓

Recover previous version

---

# S3 Encryption

We enabled

```
encrypt = true
```

State contains

- Resource IDs
- IP addresses
- Outputs
- Metadata

Encryption protects this sensitive information.

---

# Our Backend Infrastructure

We created

```
backend/

main.tf

variables.tf

outputs.tf
```

This Terraform project created

✔ S3 Bucket

✔ Bucket Versioning

✔ Bucket Encryption

✔ Public Access Block

✔ DynamoDB Table

---

# What did we actually do?

Phase sequence

Local State

↓

Created backend project

↓

Created S3 Bucket

↓

Created DynamoDB

↓

Configured backend.tf

↓

Created dev.hcl

↓

Created stage.hcl

↓

Created prod.hcl

↓

Ran terraform init

↓

Migrated state

↓

Verified state stored in S3

---

# How did we verify?

We executed

```bash
terraform state pull
```

Terraform downloaded state from S3.

We also verified objects using

```bash
aws s3 ls
```

---

# Troubleshooting We Faced

## Issue 1

Terraform asked for bucket name during init.

### Why?

Backend block still contained partial configuration.

Terraform expected remaining values interactively.

### Solution

Move all backend values into

```
dev.hcl
```

Keep backend.tf empty.

---

## Issue 2

```
Backend initialization required
```

### Why?

Backend configuration changed.

Terraform cache became outdated.

### Solution

```
terraform init -reconfigure
```

---

## Issue 3

```
Workspace doesn't exist
```

### Why?

State for that workspace had not been created.

### Solution

Create workspace

or

Select existing workspace after backend initialization.

---

## Issue 4

```
No state file found
```

### Why?

Workspace existed but infrastructure had never been applied.

State remained empty.

---

## Issue 5

State showed

```
resources: []
```

### Why?

Infrastructure already destroyed.

Terraform removed managed resources from state.

---

## Issue 6

Destroy failed because bucket was not empty.

### Error

```
BucketNotEmpty
```

### Why?

S3 Versioning was enabled.

Deleting current objects is not enough.

Previous versions also exist.

### Solution

Delete

✔ Object Versions

✔ Delete Markers

Then destroy bucket.

---

## Issue 7

Terraform state disappeared after manual AWS deletion.

### Why?

Resources were deleted outside Terraform.

Terraform state became inconsistent.

### Solution

Either

```
terraform refresh
```

or

```
terraform state rm
```

or recreate infrastructure.

---

# Best Practices

Never edit state manually.

Enable versioning.

Enable encryption.

Use locking.

Store backend separately.

One backend per project.

Separate state per environment.

Never share local state.

---

# Interview Questions

## Q1. What is Terraform State?

### Answer

Terraform State is a JSON file that stores the current mapping between Terraform configuration and real infrastructure. It enables Terraform to determine what already exists and what changes need to be made.

---

## Q2. Why is Remote State required?

### Answer

Remote State allows multiple team members to collaborate safely. It provides centralized storage, backups, versioning, and state locking, making it suitable for production environments.

---

## Q3. Why did you use S3?

### Answer

S3 is durable, highly available, supports versioning and encryption, integrates natively with Terraform, and is the recommended backend for AWS environments.

---

## Q4. Why did you use DynamoDB?

### Answer

DynamoDB provides distributed locking. It ensures only one Terraform operation can modify the state at a time, preventing concurrent updates and state corruption.

---

## Q5. What happens during `terraform init` with an S3 backend?

### Answer

Terraform reads the backend configuration, connects to S3, downloads the existing state (if present), configures the backend locally, initializes providers and modules, and prepares the working directory.

---

## Q6. Why did you keep `backend.tf` empty?

### Answer

Keeping the backend block empty allows backend configuration to be supplied externally using `.hcl` files. This makes the same code reusable across development, staging, and production environments.

---

## Q7. Why did you create separate backend files for dev, stage, and prod?

### Answer

Each environment requires a different state file. Separate `.hcl` files provide different state keys while reusing the same Terraform codebase.

---

## Q8. What is state locking?

### Answer

State locking is a mechanism that prevents multiple users from modifying the same Terraform state simultaneously. Terraform acquires a lock before making changes and releases it after the operation completes.

---

## Q9. What happens if the lock cannot be acquired?

### Answer

Terraform waits for the lock or fails with a lock acquisition error. This protects the state from concurrent modifications.

---

## Q10. Why should state files never be deleted manually?

### Answer

Deleting or modifying state files manually can orphan infrastructure, create duplicate resources, or cause Terraform to lose track of managed resources. Always manage state using Terraform commands.