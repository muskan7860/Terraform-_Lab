# Phase 12 - Terraform State (Complete Deep Dive)

---

# Goal

Terraform State is one of the most important concepts in Terraform.

Many engineers can write Terraform code, but very few truly understand how Terraform knows what it has already created.

By the end of this document you will understand:

- What Terraform State is
- Why Terraform needs State
- How State works internally
- Local State
- Remote State
- State Locking
- State File Structure
- State Lifecycle
- State Commands
- State Drift
- Import Existing Resources
- State Recovery
- Best Practices
- Enterprise Architecture
- Troubleshooting
- Interview Questions with Answers

---

# What is Terraform State?

Terraform State is a JSON file that stores the current mapping between your Terraform configuration and the real infrastructure.

Think of it as Terraform's memory.

Without the state file, Terraform forgets everything it has created.

---

# Why Does Terraform Need State?

Imagine Terraform created:

- VPC
- Subnet
- EC2
- Security Group

Tomorrow you execute

terraform apply

How will Terraform know

✔ EC2 already exists?

✔ VPC already exists?

✔ Security Group already exists?

It checks the State File.

---

# Real Life Analogy

Imagine constructing a building.

Blueprint

↓

Workers build rooms

↓

Architect writes progress into notebook

Tomorrow

Workers continue using notebook.

Terraform State is that notebook.

---

# Infrastructure Without State

Terraform Apply

↓

Create EC2

↓

Finish

Tomorrow

Terraform Apply

Terraform has no memory.

It creates another EC2.

Duplicate infrastructure.

---

# Infrastructure With State

Terraform Apply

↓

Create EC2

↓

Write EC2 ID into State

Tomorrow

Terraform Apply

↓

Reads State

↓

Compares

↓

Nothing changed

↓

No Action

---

# Where is State Stored?

Default

terraform.tfstate

Inside project directory.

Example

project/

terraform.tfstate

---

# Local State

Default storage.

Stored on developer laptop.

Example

terraform.tfstate

Advantages

Simple

No AWS required

Easy learning

Disadvantages

Not shared

No locking

Can be deleted

Risk of corruption

---

# Remote State

State stored outside local machine.

Common backends

AWS S3

Azure Storage

GCS

Terraform Cloud

Consul

Remote State enables

✔ Team collaboration

✔ State locking

✔ Backup

✔ High availability

---

# Our Project

We implemented

AWS S3 Backend

+

DynamoDB Lock Table

Flow

Terraform

↓

S3 Bucket

↓

terraform.tfstate

↓

DynamoDB

↓

Lock

---

# Why Store State in S3?

Because

Developers

↓

CI/CD

↓

GitHub Actions

↓

Jenkins

↓

Terraform Cloud

can all access the same State.

---

# Why Use DynamoDB?

Imagine

Developer A

terraform apply

Developer B

terraform apply

Both modify State simultaneously.

Result

State corruption.

DynamoDB prevents this.

Only one apply can happen.

---

# State Locking

Process

Developer A

↓

Acquire Lock

↓

Apply

↓

Release Lock

Developer B waits.

---

# Backend Configuration

Our project

backend.tf

```

terraform {

backend "s3" {}

}

```

Actual values

dev.hcl

```

bucket = "terraform-megha-project-tfstate"

key = "dev/terraform.tfstate"

region = "ap-south-1"

dynamodb_table = "terraform-megha-project-locks"

encrypt = true

```

---

# Why Separate Backend Config?

Security.

Never hardcode

Bucket

Region

Table

inside backend block.

Different environments

dev.hcl

stage.hcl

prod.hcl

use different backend configuration.

---

# State File Structure

Terraform State stores

Terraform Version

↓

Resources

↓

Attributes

↓

Dependencies

↓

Outputs

↓

Metadata

---

Example

```

{

"resources":[

{

"type":"aws_instance",

"name":"ec2"

}

]

}

```

---

# What Information is Stored?

Resource ID

AMI

Subnet

Security Group

Tags

Outputs

Dependencies

Provider Version

Resource Attributes

Everything Terraform needs.

---

# How Terraform Uses State

terraform plan

↓

Read Configuration

↓

Read State

↓

Query AWS

↓

Compare

↓

Show Difference

---

# Desired State

Terraform Code

↓

What SHOULD exist

---

# Actual State

AWS Infrastructure

↓

What DOES exist

---

# State

Terraform Memory

↓

What Terraform BELIEVES exists

---

Terraform compares all three.

---

# State Lifecycle

terraform apply

↓

Resource Created

↓

State Updated

↓

Upload to S3

↓

Lock Released

---

# Terraform State Commands

View State

```

terraform state list

```

---

Show Resource

```

terraform state show module.ec2.aws_instance.ec2[0]

```

---

Pull State

```

terraform state pull

```

Downloads remote state.

---

List Resources

```

terraform state list

```

Output

```

module.vpc.aws_vpc.main

module.ec2.aws_instance.ec2

```

---

Move State

```

terraform state mv

```

Used during refactoring.

---

Remove Resource

```

terraform state rm

```

Removes only from State.

AWS resource remains.

---

Replace Provider

```

terraform state replace-provider

```

Enterprise migration.

---

# State Drift

Suppose Terraform created EC2.

You manually delete EC2 in AWS Console.

Terraform State still says

EC2 exists.

This mismatch is called

State Drift.

---

# Example

Terraform State

EC2 exists

AWS

EC2 deleted

terraform plan

↓

Terraform recreates EC2.

---

# Our Real Example

We manually deleted

Dev EC2

Terraform State became inconsistent.

Solution

terraform apply

or

terraform state rm

depending on scenario.

---

# Import Existing Infrastructure

Suppose AWS already has

VPC

Terraform knows nothing.

Import

```

terraform import aws_vpc.main vpc-123456

```

Terraform now manages it.

---

# Refresh

Terraform compares AWS with State.

```

terraform refresh

```

(Deprecated)

Modern versions automatically refresh during plan.

---

# State Backup

Always backup State.

Example

```

terraform state pull > backup.tfstate

```

---

# Can We Edit State?

Yes.

Should We?

Almost never.

Incorrect edits may destroy infrastructure.

---

# Enterprise Best Practices

✔ Remote Backend

✔ Versioning Enabled

✔ Encryption Enabled

✔ Locking Enabled

✔ Least Privilege IAM

✔ Separate State Per Environment

✔ Never Commit State to Git

✔ Backup State

✔ Protect S3 Bucket

---

# Common Mistakes

Mistake

Deleting State File

Result

Terraform recreates everything.

---

Mistake

Manual AWS changes

Result

State Drift.

---

Mistake

Sharing Local State

Result

Conflicts.

---

Mistake

No Locking

Result

Corrupted State.

---

Mistake

Editing State Manually

Result

Infrastructure mismatch.

---

# Troubleshooting

## Problem

No state file found

Reason

Backend empty

Never applied

Wrong workspace

Wrong backend

---

## Problem

State Lock

Error

```

ConditionalCheckFailedException

```

Reason

Someone else running Apply.

---

Solution

Wait

or

```

terraform force-unlock LOCK_ID

```

---

## Problem

State Drift

Reason

Manual AWS changes.

Solution

terraform plan

terraform apply

or

terraform import

---

## Problem

Backend changed

Solution

```

terraform init -reconfigure

```

---

# Our Project Flow

Backend Project

↓

Created

S3

↓

Created

DynamoDB

↓

Configured Backend

↓

terraform init

↓

Remote State Active

↓

Applied Dev

↓

Applied Stage

↓

Applied Prod

↓

Verified State

↓

State Stored in S3

---

# Interview Questions

## Q1 What is Terraform State?

### Answer

Terraform State is a JSON file that stores the mapping between Terraform configuration and real infrastructure so Terraform knows what resources it manages.

---

## Q2 Why does Terraform require State?

### Answer

Without State, Terraform cannot determine whether resources already exist, leading to duplicate infrastructure.

---

## Q3 What is State Drift?

### Answer

State Drift occurs when infrastructure is changed outside Terraform, causing the State file and actual infrastructure to become inconsistent.

---

## Q4 Local State vs Remote State?

### Answer

Local State is stored on the local machine and is suitable only for learning.

Remote State is stored centrally (such as AWS S3), allowing team collaboration, backups, and locking.

---

## Q5 Why use S3?

### Answer

To provide centralized, durable, and shared storage for Terraform State across multiple users and automation systems.

---

## Q6 Why use DynamoDB?

### Answer

To provide state locking, ensuring that only one Terraform operation can modify the state at a time and preventing corruption.

---

## Q7 What is terraform state list?

### Answer

Lists all resources currently tracked by Terraform State.

---

## Q8 What is terraform state show?

### Answer

Displays detailed information about a single resource stored in the State.

---

## Q9 What happens if the State file is deleted?

### Answer

Terraform loses its memory of managed resources. Running `terraform apply` may attempt to recreate existing infrastructure.

---

## Q10 Why should State never be committed to Git?

### Answer

The State file may contain infrastructure metadata and sensitive information. It also changes frequently, causing merge conflicts and security risks.

---

# Key Takeaways

✔ Terraform State is Terraform's memory.

✔ Terraform compares Configuration, State, and Actual Infrastructure.

✔ Local State is suitable only for learning.

✔ Remote State is mandatory for production environments.

✔ S3 stores the state.

✔ DynamoDB prevents concurrent modifications through state locking.

✔ Never edit the State file manually unless absolutely necessary.

✔ Protect and back up the State because it is one of the most critical assets in any Terraform project.