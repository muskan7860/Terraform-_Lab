# Phase 8 - Terraform State Management (Complete Deep Dive)

---

# Goal

In this phase we learned one of the most important concepts in Terraform:

> Terraform State.

Many beginners think Terraform creates infrastructure directly.

It doesn't.

Terraform first compares

Current Infrastructure

with

Terraform State

and

Terraform Code

then decides

Create

Update

Delete

Nothing

Everything revolves around the State file.

Without understanding State you cannot become a good Terraform Engineer.

---

# What is Terraform State?

Terraform State is a JSON file that records everything Terraform has created.

It acts as Terraform's database.

Example

Terraform creates

EC2

↓

Terraform immediately records

Instance ID

AMI

Security Group

Subnet

Tags

Attributes

Dependencies

inside

terraform.tfstate

---

# Why Terraform Needs State

Imagine Terraform created

```
EC2 Instance

ID = i-12345
```

Tomorrow you change

```
instance_type

t3.micro

↓

t3.small
```

Question

How does Terraform know

which EC2

must be modified?

Answer

State file.

Without State

Terraform would have no idea

which infrastructure belongs to it.

---

# Think Like This

Terraform Configuration

↓

Desired State

Terraform State

↓

Current Known State

AWS Infrastructure

↓

Actual Infrastructure

Terraform compares

Desired

vs

Known

vs

Actual

Then creates an execution plan.

---

# Life Cycle of Terraform State

Step 1

You write

```
main.tf
```

↓

Step 2

Run

```
terraform apply
```

↓

Step 3

Terraform calls AWS APIs

↓

Step 4

AWS creates resources

↓

Step 5

Terraform stores every resource

inside State.

---

# State is NOT Configuration

Many beginners confuse these.

Configuration

contains

"What I WANT"

State

contains

"What EXISTS"

Huge difference.

---

# Example

Configuration

```
resource "aws_instance" "web"
```

State

```
Instance ID

AMI

Subnet

Private IP

Public IP

ARN

Security Group

Volumes

Metadata
```

Configuration is very small.

State is extremely detailed.

---

# Why JSON?

Terraform stores state as JSON because

Machine readable

Easy to compare

Easy to parse

Portable

---

# Example State Structure

```
Version

Terraform Version

Resources

Outputs

Dependencies

Provider Information

Lineage

Serial Number
```

---

# State File Components

Version

Terraform State Version

Terraform Version

Version used to create state

Lineage

Unique identity of state

Serial

Increments after every Apply

Outputs

Stores output variables

Resources

Stores every managed resource

---

# Resources Section

Every resource contains

Resource Type

Resource Name

Provider

Attributes

Dependencies

IDs

Example

```
aws_instance

↓

id

ami

instance_type

private_ip

public_ip

availability_zone

subnet_id
```

---

# Serial Number

Every Apply

increments

Serial.

Example

```
Apply 1

Serial 1

Apply 2

Serial 2

Apply 3

Serial 3
```

Useful for

Detecting newer states

Avoiding overwrites

---

# Lineage

Lineage uniquely identifies one Terraform State.

Even if

Filename changes

Bucket changes

Workspace changes

Terraform still knows

whether it is

same state

or

new state.

---

# Local State

Initially Terraform stores

```
terraform.tfstate
```

inside project directory.

Problem

Only available on one laptop.

Not safe.

---

# Problems with Local State

Developer A

↓

Has State

Developer B

↓

No State

Now

Both run Apply.

Infrastructure becomes inconsistent.

---

# Remote State

Instead of local machine

store state

inside

S3

Terraform Cloud

Azure Storage

GCS

Consul

etc.

---

# Our Project

Initially

```
terraform.tfstate
```

Later

Migrated

↓

S3 Backend

Bucket

```
terraform-megha-project-tfstate
```

---

# Why S3?

Centralized

Highly Available

Versioning

Encryption

Easy Backup

Collaboration

---

# Why DynamoDB?

State Locking.

Imagine

Developer A

↓

terraform apply

Developer B

↓

terraform apply

Same time.

Without locking

State corruption.

With DynamoDB

Terraform locks state

until first operation completes.

---

# What Happens During Apply?

Terraform

↓

Reads State

↓

Locks DynamoDB

↓

Reads Infrastructure

↓

Creates Plan

↓

Executes Changes

↓

Updates State

↓

Unlocks DynamoDB

---

# Backend Flow

Developer

↓

Terraform

↓

Lock Table

↓

S3 State

↓

AWS APIs

↓

Infrastructure

---

# State Commands

## Show Current State

```bash
terraform state list
```

Output

```
module.ec2.aws_instance.web

module.vpc.aws_vpc.main
```

---

## Pull State

```bash
terraform state pull
```

Downloads current state from backend.

Useful for inspection.

---

## Show Resource

```bash
terraform state show module.ec2.aws_instance.ec2[0]
```

Shows complete resource attributes.

---

## Remove Resource from State

```bash
terraform state rm
```

Removes only Terraform tracking.

Does NOT delete AWS resource.

---

## Move Resource

```bash
terraform state mv
```

Useful after renaming modules.

---

## Replace Provider

```bash
terraform state replace-provider
```

Used when migrating providers.

---

# What Happens During Plan?

Terraform performs

State

↓

Refresh

↓

Configuration

↓

Diff

↓

Execution Plan

---

# Refresh

Terraform asks AWS

"What actually exists?"

If

Manual changes happened

Terraform detects drift.

---

# Infrastructure Drift

Example

Terraform created

```
EC2

Type

t3.micro
```

Someone changes

Console

↓

t3.small

Terraform detects

Difference

↓

Shows

Plan.

---

# State Locking

When Apply starts

Terraform writes

Lock Record

inside DynamoDB.

Other users receive

```
State already locked
```

until operation finishes.

---

# Why Locking Matters

Without locking

Two engineers

update

same state

at same time.

Result

Corrupted state

Duplicate resources

Lost updates

---

# Versioning

Our S3 bucket

enabled

Versioning.

Meaning

Every state update

creates

new version.

Benefits

Rollback

Recovery

Audit

Accidental deletion recovery

---

# Problems We Faced

## Problem 1

terraform state list

↓

No state file found

Reason

Workspace empty.

No resources managed.

---

## Problem 2

terraform destroy

↓

0 destroyed

Reason

Current workspace

had empty state.

---

## Problem 3

Manual EC2 deletion

AWS Console

↓

Terraform still tracked resource.

Next Plan detected drift.

---

## Problem 4

Wrong backend initialization

Used

dev backend

inside

stage workspace.

Result

Unexpected state path.

---

## Problem 5

Bucket deletion failed

Error

```
BucketNotEmpty
```

Reason

S3 Versioning enabled.

Deleting objects

is NOT enough.

All versions

must be removed.

---

# State Best Practices

Never edit state manually.

Always use remote backend.

Enable versioning.

Enable encryption.

Enable locking.

Never share local state.

Never commit state to Git.

Backup state.

Never delete infrastructure manually.

---

# Files That Should Never Go to GitHub

```
terraform.tfstate

terraform.tfstate.backup

.terraform/

*.tfvars

crash.log
```

Use

```
.gitignore
```

---

# How We Verified State

Commands used

```bash
terraform state list
```

```bash
terraform state pull
```

```bash
terraform workspace show
```

```bash
aws s3 ls
```

```bash
aws s3api list-object-versions
```

These helped us debug backend issues.

---

# Interview Questions

## Q1. What is Terraform State?

### Answer

Terraform State is a JSON file that stores metadata about all infrastructure managed by Terraform. It maps Terraform configuration to real cloud resources and enables Terraform to calculate infrastructure changes.

---

## Q2. Why is State required?

### Answer

Terraform needs state to identify existing resources, detect changes, update infrastructure safely, and maintain resource dependencies.

---

## Q3. Why should State not be stored locally?

### Answer

Local state is available only on one machine. It is difficult to collaborate, prone to accidental deletion, lacks locking, and cannot support teams effectively.

---

## Q4. Why use an S3 backend?

### Answer

Amazon S3 provides centralized storage, durability, versioning, encryption, and allows multiple engineers and CI/CD pipelines to access the same Terraform state safely.

---

## Q5. Why is DynamoDB used with S3?

### Answer

DynamoDB provides state locking. It prevents multiple users or pipelines from modifying the same Terraform state simultaneously, avoiding corruption.

---

## Q6. What happens if someone manually deletes an EC2 instance?

### Answer

Terraform State still contains the resource. During the next plan or apply, Terraform detects that the infrastructure has drifted and attempts to recreate or reconcile the resource.

---

## Q7. What is Infrastructure Drift?

### Answer

Infrastructure Drift occurs when real infrastructure differs from the Terraform configuration or state because of manual changes outside Terraform.

---

## Q8. What is `terraform state list`?

### Answer

It lists all resources currently tracked in the Terraform state file.

---

## Q9. What is `terraform state pull`?

### Answer

It downloads and displays the current Terraform state from the configured backend without modifying it.

---

## Q10. Why did your S3 bucket fail to delete?

### Answer

Versioning was enabled. Although the current objects were deleted, previous object versions still existed. Amazon S3 does not allow deletion of a versioned bucket until every object version and delete marker has been removed.

---

## Q11. Why should you never manually edit the state file?

### Answer

Manual modifications can corrupt the state, break resource mappings, cause infrastructure inconsistencies, and make future Terraform operations unreliable.

---

## Key Takeaways

✔ Terraform State is Terraform's database.

✔ State maps configuration to real infrastructure.

✔ S3 stores remote state.

✔ DynamoDB prevents concurrent updates.

✔ Versioning protects against accidental loss.

✔ State should never be committed to Git.

✔ Always verify the active workspace before running apply or destroy.

✔ Understanding State is essential for debugging, collaboration, and production-grade Terraform workflows.