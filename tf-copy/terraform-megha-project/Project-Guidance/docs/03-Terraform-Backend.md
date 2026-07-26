# Phase 3 - Terraform Remote Backend (S3 + DynamoDB)

---

# Goal

After this phase Terraform state will no longer be stored on your laptop.

Instead,

Laptop
        ↓
Terraform
        ↓
AWS S3 Bucket
        ↓
State File

At the same time DynamoDB will protect the state from multiple engineers changing it simultaneously.

This is exactly how Terraform is used inside companies.

---

# Why do we need Remote Backend?

Suppose two DevOps Engineers are working.

Engineer A
Engineer B

Both clone the same repository.

Both have their own terraform.tfstate.

Engineer A creates EC2.

Engineer B creates VPC.

Now two different state files exist.

Terraform can no longer understand what infrastructure actually exists.

Infrastructure becomes inconsistent.

This problem is called

State Drift

Remote Backend solves this problem.

---

# Local Backend

Default Terraform

Laptop

terraform.tfstate

Problems

❌ State lost if laptop crashes

❌ Cannot collaborate

❌ No locking

❌ Multiple engineers overwrite state

❌ Not production ready

---

# Remote Backend

Terraform

↓

S3 Bucket

↓

terraform.tfstate

↓

DynamoDB

↓

Lock

Advantages

✔ Single Source of Truth

✔ Team Collaboration

✔ Version History

✔ Locking

✔ Encryption

✔ High Availability

✔ Disaster Recovery

---

# Architecture

Developer

↓

terraform plan

↓

terraform apply

↓

Terraform Core

↓

AWS Provider

↓

S3 Bucket

(terraform.tfstate)

↓

DynamoDB

(terraform-lock)

↓

AWS Resources

EC2

VPC

Security Group

Subnet

Internet Gateway

---

# Components

## 1. S3 Bucket

Purpose

Stores terraform state file.

Example

terraform-megha-project-tfstate

Inside bucket

dev/terraform.tfstate

prod/terraform.tfstate

stage/terraform.tfstate

Terraform reads this file every time before planning.

---

## 2. DynamoDB Table

Purpose

Stores lock.

Example

terraform-megha-project-locks

Primary Key

LockID

Terraform creates temporary lock.

Lock acquired

↓

No other engineer can modify infrastructure.

After apply

↓

Lock removed.

---

# Backend Configuration

Initially

backend.tf

terraform {

backend "s3" {}

}

Notice

No bucket name is written.

Why?

Because different environments have different backend configuration.

We pass it during initialization.

Example

terraform init \
-reconfigure \
-backend-config=../backend/dev.hcl

This loads

dev.hcl

bucket

key

region

dynamodb table

---

# Backend Config File

Example

bucket = "terraform-megha-project-tfstate"

key = "dev/terraform.tfstate"

region = "ap-south-1"

dynamodb_table = "terraform-megha-project-locks"

encrypt = true

Explanation

bucket

S3 bucket

key

Location of tfstate

region

AWS Region

dynamodb_table

State lock

encrypt

Encrypt state

---

# What happens during terraform init?

Step 1

Terraform reads backend block.

↓

Backend is S3.

Step 2

Reads dev.hcl

↓

Gets bucket

↓

Gets key

↓

Gets region

↓

Gets lock table

↓

Connects to AWS

↓

Checks bucket exists

↓

Checks DynamoDB exists

↓

Downloads state

↓

Initialization complete

---

# What happens during terraform plan?

Terraform first downloads latest state.

↓

Compares

Desired configuration

vs

Actual infrastructure

↓

Generates execution plan.

No resource is created.

---

# What happens during terraform apply?

Acquire Lock

↓

Download latest state

↓

Compare infrastructure

↓

Create resources

↓

Update tfstate

↓

Upload tfstate to S3

↓

Release lock

---

# Why is State Important?

Terraform does NOT scan entire AWS account.

Instead

Terraform trusts

terraform.tfstate

State contains

Resource IDs

Dependencies

Outputs

Metadata

Attributes

Without state

Terraform cannot know

What already exists.

---

# Workspace Concept

Workspace separates state.

Example

dev

↓

dev/terraform.tfstate

stage

↓

stage/terraform.tfstate

prod

↓

prod/terraform.tfstate

Each environment has independent infrastructure.

---

# What we did

Created S3 Bucket

Created DynamoDB Table

Created backend module

Created backend.tf

Created

dev.hcl

stage.hcl

prod.hcl

Initialized backend

Migrated state

Created workspaces

Applied resources

Verified state stored in S3

Verified locking

Destroyed resources

---

# Errors We Faced

## Error

Backend initialization required

Reason

Backend changed.

Solution

terraform init -reconfigure

---

## Error

Terraform asks bucket name

Reason

Backend block still had configuration.

Solution

Keep backend block empty.

backend "s3" {}

Pass configuration through

-backend-config

---

## Error

No state file found

Reason

Workspace empty.

No apply done.

Solution

Run terraform apply

---

## Error

Workspace not found

Reason

Workspace never created.

Solution

terraform workspace new dev

---

## Error

BucketNotEmpty

Reason

S3 Versioning enabled.

Old versions exist.

Solution

Delete every object version.

Then delete bucket.

---

## Error

No changes to destroy

Reason

State empty.

Infrastructure already removed.

Terraform only destroys resources present in state.

---

# Best Practices

Always use Remote Backend.

Never commit tfstate.

Enable Versioning.

Enable Encryption.

Enable Locking.

Separate environments.

Store backend separately.

Never manually edit tfstate.

---

# Production Notes

Large companies

Create one shared backend.

Example

terraform-backend

↓

S3

↓

Versioning Enabled

↓

Encryption Enabled

↓

Access Logs

↓

IAM Policies

↓

DynamoDB Lock

Every Terraform project uses this backend.

---

# Interview Questions

## Q1 Why do we use Remote Backend?

Answer

Remote backend centralizes the Terraform state so multiple engineers can safely work on the same infrastructure. It prevents state conflicts, supports collaboration, enables disaster recovery, and stores the state securely in S3 with locking through DynamoDB.

---

## Q2 Why S3?

Answer

S3 provides highly durable object storage, supports versioning, encryption, lifecycle policies, IAM integration, and is cost-effective. Terraform uses it to store state files reliably.

---

## Q3 Why DynamoDB?

Answer

DynamoDB provides state locking. Before Terraform modifies infrastructure, it creates a lock record. This prevents two engineers from running `terraform apply` simultaneously and corrupting the state.

---

## Q4 What happens if two engineers run apply at the same time?

Answer

The first engineer acquires the lock in DynamoDB. The second engineer receives a state lock error and must wait until the first operation completes.

---

## Q5 What is stored in terraform.tfstate?

Answer

The state file stores resource IDs, metadata, outputs, dependencies, current attribute values, and mappings between Terraform configuration and real infrastructure. Terraform relies on it instead of scanning the cloud every time.

---

## Q6 Can Terraform work without a state file?

Answer

Not effectively. Terraform needs the state file to know which resources it already manages. Without it, Terraform may attempt to recreate existing resources or lose track of them.

---

## Q7 Why should we never manually edit the state file?

Answer

The state file is Terraform's source of truth. Manual changes can corrupt resource mappings, causing failed plans, duplicate resources, or accidental deletions.

---

## Q8 Why do we use backend-config files instead of hardcoding values?

Answer

Using separate `.hcl` backend configuration files allows different environments (dev, stage, prod) to use different state locations without modifying Terraform code. It improves reusability and security.

---

## Q9 What is the difference between workspaces and backend keys?

Answer

Workspaces create separate state instances within the backend. Backend keys define the object path in S3 where a specific state file is stored. Together they isolate environments.

---

## Q10 Explain your backend setup in your project.

Answer

I provisioned an S3 bucket with versioning and encryption enabled to store Terraform state files. I created a DynamoDB table for state locking. I kept the backend block empty and passed environment-specific configuration using `-backend-config`. I created separate workspaces for dev, stage, and prod, ensuring isolated state files for each environment.