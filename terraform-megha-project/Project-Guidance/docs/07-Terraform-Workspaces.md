# Phase 7 - Terraform Workspaces (Multi-Environment Infrastructure)

---

# Goal

In this phase, we implemented Terraform Workspaces to manage multiple environments (Development, Staging, and Production) using the same Terraform codebase while maintaining completely separate state files.

Instead of copying Terraform code into three different folders (dev, stage, prod), we reused one codebase and isolated each environment using Terraform Workspaces.

This is the industry-standard approach for small to medium-sized Infrastructure as Code projects.

---

# Real Problem Before Workspaces

Suppose your company has three environments:

```
Development

Staging

Production
```

Without workspaces, you might create folders like:

```
terraform/

dev/

main.tf

variables.tf

stage/

main.tf

variables.tf

prod/

main.tf

variables.tf
```

Immediately you have problems.

Every code change must be copied three times.

Every bug fix must be repeated.

Huge maintenance effort.

Risk of configuration drift.

---

# Configuration Drift

Configuration Drift means two environments no longer use the same infrastructure code.

Example

Developer updates

```
instance_type = "t3.small"
```

inside Dev

But forgets to update Production.

Now

Dev

↓

t3.small

Production

↓

t3.micro

Same application.

Different infrastructure.

Unexpected behavior.

---

# Better Solution

Instead of

```
dev/

stage/

prod/
```

Terraform introduced

```
Workspaces
```

Now we keep

```
One Code

Three States
```

---

# What is a Workspace?

A Workspace is an isolated Terraform State.

Remember

Terraform configuration remains the same.

Only the State changes.

Think of it like this:

```
Terraform Code

↓

Workspace

↓

State File

↓

Infrastructure
```

Different Workspace

↓

Different State

↓

Different Infrastructure

---

# Important Concept

Terraform Workspaces DO NOT duplicate code.

They only create different state files.

Same Terraform

↓

Different State

↓

Different Resources

---

# Our Project Structure

```
terraform-megha-project

infra-app/

main.tf

variables.tf

outputs.tf

backend.tf

modules/

backend/

dev.hcl

stage.hcl

prod.hcl
```

Notice

There are NOT

```
dev/

stage/

prod/
```

folders.

One codebase.

---

# Workspaces We Created

Initially

```
default
```

Then

```
dev

stage

prod
```

---

# How to List Workspaces

```bash
terraform workspace list
```

Example

```
default

dev

stage

prod
```

Current workspace shows

```
*
```

Example

```
default

* dev

stage

prod
```

---

# Create Workspace

```bash
terraform workspace new dev
```

Terraform creates

A new empty state.

Nothing else.

---

# Select Workspace

```bash
terraform workspace select stage
```

Now Terraform switches to Stage state.

Nothing changes in Terraform code.

Only the backend state changes.

---

# Show Current Workspace

```bash
terraform workspace show
```

Example

```
dev
```

---

# Workspace Flow

```
terraform workspace select dev

↓

terraform plan

↓

terraform apply

↓

Resources created

↓

State stored in

dev
```

Now switch

```
terraform workspace select stage
```

Terraform sees

Empty state

↓

Plan again

↓

Creates Stage Infrastructure

---

# Our Workflow

We repeated

```
Workspace

↓

Plan

↓

Apply
```

For

Dev

↓

Stage

↓

Prod

Every workspace created separate infrastructure.

---

# How State is Stored

Initially we expected

```
dev/terraform.tfstate

stage/terraform.tfstate

prod/terraform.tfstate
```

However,

Terraform Workspaces automatically modify the path.

Actual paths became

```
env:/dev/dev/terraform.tfstate

env:/stage/stage/terraform.tfstate

env:/prod/prod/terraform.tfstate
```

This surprised us during troubleshooting.

---

# Why did Terraform create env:/ ?

Terraform automatically prefixes non-default workspaces with

```
env:/
```

when using an S3 backend.

Default workspace behaves differently.

Non-default workspaces are automatically namespaced.

---

# Why did Stage create a Dev state earlier?

During our implementation we accidentally initialized the backend using

```
dev.hcl
```

while working inside

```
stage
```

workspace.

Terraform therefore generated paths like

```
env:/stage/dev/terraform.tfstate
```

instead of

```
env:/stage/stage/terraform.tfstate
```

This happened because the backend key and current workspace did not match.

---

# Lesson Learned

Always verify

```
terraform workspace show
```

AND

Backend file

before running

```
terraform init

terraform apply
```

---

# How Terraform Chooses State

Terraform combines

Workspace

+

Backend Key

to determine the final S3 object path.

Example

Workspace

```
stage
```

Backend

```
key = "stage/terraform.tfstate"
```

Final path becomes

```
env:/stage/stage/terraform.tfstate
```

---

# How We Verified State

We checked

```bash
terraform state pull
```

Returned

```
resources
```

showing the exact resources inside the current workspace.

We also checked

```bash
terraform state list
```

to verify managed resources.

---

# Destroying Resources

Destroy only affects the current workspace.

Example

Current Workspace

```
dev
```

Command

```bash
terraform destroy
```

Only

Development

is destroyed.

Stage

↓

Still exists

Production

↓

Still exists

---

# Important Mistake We Made

We manually deleted EC2 instances from AWS Console.

Terraform state still believed those resources existed.

This caused

Unexpected state mismatch.

---

# Correct Way

Always use

```bash
terraform destroy
```

instead of deleting manually.

Terraform keeps state synchronized.

---

# Another Mistake We Faced

```
terraform destroy

↓

No resources destroyed
```

Why?

Because

Current workspace had

```
resources : []
```

State was already empty.

Terraform had nothing to delete.

---

# How to Verify Running Resources

We used AWS CLI

```bash
aws ec2 describe-instances \
--region ap-south-1 \
--filters "Name=instance-state-name,Values=running"
```

Output

```
Dev EC2

Stage EC2

Prod EC2
```

This confirmed all three workspaces had separate infrastructure.

---

# Workspace Best Practices

✔ One codebase

✔ Separate states

✔ Same modules

✔ Environment variables

✔ Different tfvars if required

✔ Never share state

✔ Never manually edit state

✔ Verify workspace before Apply

---

# Commands Used

Create Workspace

```bash
terraform workspace new dev
```

List

```bash
terraform workspace list
```

Show

```bash
terraform workspace show
```

Select

```bash
terraform workspace select stage
```

Delete

```bash
terraform workspace delete dev
```

Destroy Current Workspace Resources

```bash
terraform destroy
```

---

# Real Production Workflow

Developer

↓

Select Workspace

↓

Initialize Backend

↓

Terraform Plan

↓

Terraform Apply

↓

State Stored in S3

↓

Lock Stored in DynamoDB

↓

Infrastructure Created

---

# Advantages of Workspaces

✔ Reuse code

✔ Separate infrastructure

✔ Separate state

✔ Easy testing

✔ Production safe

✔ Team collaboration

✔ Simple promotion workflow

---

# Limitations

Large enterprises usually don't rely only on workspaces.

Instead they often use

Separate AWS Accounts

Separate Terraform Repositories

Separate Backend Buckets

CI/CD pipelines

Terraform Cloud

Workspaces are excellent for learning and small-to-medium environments.

---

# Interview Questions

## Q1. What are Terraform Workspaces?

### Answer

Terraform Workspaces allow multiple independent state files to be managed using the same Terraform configuration. They enable infrastructure separation for environments such as development, staging, and production without duplicating code.

---

## Q2. Why did you use Workspaces?

### Answer

We wanted to deploy the same infrastructure into multiple environments while keeping the Terraform code identical. Workspaces isolated the state for each environment, preventing resource conflicts.

---

## Q3. Do Workspaces create different code?

### Answer

No. Workspaces do not duplicate Terraform code. They only maintain separate state files. The same configuration is executed against different state backends.

---

## Q4. What changes when you switch workspaces?

### Answer

Only the active Terraform state changes. The Terraform configuration files remain the same. Terraform begins reading and writing to the state associated with the selected workspace.

---

## Q5. Why did your S3 bucket contain paths like `env:/stage/stage/terraform.tfstate`?

### Answer

Terraform automatically prefixes non-default workspaces with `env:/`. The workspace name is combined with the backend key to generate the final object path in the S3 backend.

---

## Q6. What happens if you run `terraform destroy` in the wrong workspace?

### Answer

Terraform destroys resources tracked by the currently selected workspace only. Running it in the wrong workspace can accidentally delete infrastructure belonging to another environment.

---

## Q7. Why should you always run `terraform workspace show` before applying changes?

### Answer

It confirms the active workspace. This helps avoid creating or destroying resources in the wrong environment.

---

## Q8. Can two workspaces manage the same resource?

### Answer

No. Each workspace has its own state. Managing the same physical resource from multiple workspaces leads to state conflicts and should be avoided.

---

## Q9. Why did `terraform destroy` show "0 resources destroyed" even though EC2 instances existed?

### Answer

Because the current workspace's state was empty. Terraform only destroys resources recorded in its state. Resources created in another workspace or deleted manually are not affected.

---

## Q10. What are the best practices when using Workspaces?

### Answer

- Use one codebase for all environments.
- Keep backend configuration separate.
- Verify the active workspace before every apply or destroy.
- Store state remotely with S3.
- Enable state locking with DynamoDB.
- Avoid manually deleting infrastructure outside Terraform.
- Use environment-specific variables and outputs where appropriate.