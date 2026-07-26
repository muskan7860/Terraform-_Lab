# Phase 10 - Terraform Workspaces (Complete Deep Dive)

---

# Goal

In this phase, we learned how Terraform Workspaces allow us to manage multiple environments (Development, Stage, Production) using the same Terraform code while keeping each environment's state completely isolated.

By the end of this phase you will understand:

• What Terraform Workspaces are
• Why Workspaces exist
• How Terraform stores Workspace State
• Default Workspace
• Creating Workspaces
• Switching Workspaces
• Backend Integration
• Workspace Folder Structure inside S3
• Common Mistakes
• Real Project Examples
• Production Best Practices
• Interview Questions with Answers

---

# What is a Terraform Workspace?

A Terraform Workspace is an isolated copy of the Terraform State.

Many beginners think a Workspace creates a new project.

This is incorrect.

Workspace DOES NOT duplicate your code.

Workspace ONLY creates a separate State file.

Think of it like this

Same Terraform Code

↓

Workspace

↓

Separate State

---

# Why Do We Need Workspaces?

Imagine a project has three environments

Development

Stage

Production

Without Workspaces

You would need

Project-Dev

Project-Stage

Project-Prod

Three different folders.

Three different terraform.tfstate files.

Hard to maintain.

Instead

One Terraform Code

Three Workspaces

Three State Files

Much cleaner.

---

# Real Example

One Code

↓

main.tf

↓

variables.tf

↓

modules/

↓

Workspace

↓

dev

↓

stage

↓

prod

Each workspace keeps its own infrastructure.

---

# What Changes Between Workspaces?

Only the State changes.

Example

Workspace

dev

contains

EC2

VPC

Security Group

Workspace

prod

contains

Another EC2

Another VPC

Another Security Group

Same code

Different resources.

---

# Our Project Structure

terraform-megha-project

↓

backend/

↓

infra-app/

↓

modules/

↓

variables.tf

↓

main.tf

↓

outputs.tf

↓

terraform.tfvars

One codebase.

Multiple workspaces.

---

# Default Workspace

Whenever Terraform initializes a project

it automatically creates

"default"

workspace.

You cannot delete it.

It always exists.

Check it

```bash
terraform workspace show
```

Output

```
default
```

---

# List Workspaces

Command

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

The current workspace

has

*

Example

```
default

* dev

stage

prod
```

---

# Create Workspace

Command

```bash
terraform workspace new dev
```

Terraform immediately

Creates Workspace

Switches Workspace

Creates State

---

# Switch Workspace

Command

```bash
terraform workspace select stage
```

Terraform loads

Stage State

NOT Dev State.

---

# Current Workspace

```bash
terraform workspace show
```

Output

```
stage
```

Always verify before

Plan

Apply

Destroy.

---

# Workspace Flow

Create

↓

Select

↓

Plan

↓

Apply

↓

Destroy

↓

Switch

Never skip checking the current workspace.

---

# Backend + Workspace

Our Backend

S3

stores

one state file

per workspace.

Example

```
S3

↓

env:/dev/

↓

terraform.tfstate
```

Stage

↓

```
env:/stage/

terraform.tfstate
```

Production

↓

```
env:/prod/

terraform.tfstate
```

Each workspace

has

its own state.

---

# Why Did We See

env:/dev/dev/

Earlier

our backend key

was

```
dev/terraform.tfstate
```

Terraform automatically prefixes

```
env:/dev/
```

Final path

```
env:/dev/

+

dev/

↓

env:/dev/dev/

terraform.tfstate
```

This confused us initially.

Now we know why.

---

# Workspace Does NOT Duplicate Code

Many people think

Workspace copies

main.tf

variables.tf

modules

No.

Only State changes.

The code remains exactly the same.

---

# What Actually Changes?

Workspace changes

terraform.workspace

Example

```
terraform.workspace

↓

dev
```

or

```
stage
```

or

```
prod
```

Terraform uses this value inside expressions.

---

# Example

Variable

```
Name = "${terraform.workspace}-ec2"
```

Results

Workspace

dev

↓

dev-ec2

Workspace

stage

↓

stage-ec2

Workspace

prod

↓

prod-ec2

Same code

Different resource names.

---

# How We Used It

Our project created

terraform-megha-project-dev-ec2-1

terraform-megha-project-stage-ec2-1

terraform-megha-project-prod-ec2-1

Automatically.

No duplicate code.

---

# State Isolation

Workspace

dev

cannot see

Stage resources.

Workspace

stage

cannot see

Prod resources.

Each state is isolated.

---

# Why Did

terraform state list

Show Nothing?

Because

Current Workspace

had an empty state.

Terraform correctly loaded

Stage Workspace

but

there were no tracked resources.

State exists.

Resources don't.

---

# Why Did

terraform destroy

Destroy Nothing?

Terraform only destroys

resources

recorded

inside the current workspace state.

If

State

is empty

Terraform destroys nothing.

---

# Common Mistake

Current Workspace

↓

stage

Running

```
terraform apply
```

Expecting

Dev resources.

Wrong.

Terraform creates

Stage resources.

Always verify

```
terraform workspace show
```

before

Apply.

---

# How We Verified

Command

```
terraform workspace list
```

Command

```
terraform workspace show
```

Command

```
terraform state pull
```

Command

```
terraform state list
```

These helped us verify

which workspace

we were actually using.

---

# Workspace Lifecycle

Create

↓

Apply

↓

Modify

↓

Destroy

↓

Workspace remains

Even after destroying resources

the workspace still exists.

Only the state becomes empty.

---

# Can We Delete a Workspace?

Yes

But

Only if

it is NOT

the current workspace.

Example

Wrong

```
terraform workspace delete dev
```

while currently inside

dev.

Correct

```
terraform workspace select default

terraform workspace delete dev
```

---

# Can We Delete Default?

No.

Terraform protects

default workspace.

It always exists.

---

# Can Multiple Engineers Use Same Workspace?

Yes

if

Backend

and

Locking

exist.

Without Backend

Workspace becomes local only.

---

# Workspace vs Folder

Workspace

One Code

Multiple States

Folder

Multiple Codes

Multiple States

---

# Which One is Better?

Small Project

↓

Workspace

Large Enterprise

↓

Separate folders

or

Separate repositories.

---

# Production Recommendation

Many companies

do NOT

use Workspaces

for Production.

Instead

They keep

```
environments/

dev/

stage/

prod/
```

Each environment

has

its own Backend

Variables

Pipeline

Approvals.

Reason

More control.

---

# When Should You Use Workspaces?

Learning Terraform

Small Projects

POCs

Labs

Simple Infrastructure

---

# When Should You Avoid Workspaces?

Large Teams

Production

Compliance Projects

Financial Systems

Healthcare Systems

Enterprise Infrastructure

---

# Real Project Workflow

Create Backend

↓

terraform init

↓

terraform workspace new dev

↓

terraform apply

↓

terraform workspace new stage

↓

terraform apply

↓

terraform workspace new prod

↓

terraform apply

Now

Three environments

Same code

Different state.

---

# Commands Cheat Sheet

Create Workspace

```bash
terraform workspace new dev
```

List Workspaces

```bash
terraform workspace list
```

Current Workspace

```bash
terraform workspace show
```

Switch Workspace

```bash
terraform workspace select stage
```

Delete Workspace

```bash
terraform workspace delete stage
```

---

# Best Practices

Always check workspace before Apply.

Never manually edit workspace state.

Use Remote Backend.

Enable DynamoDB Locking.

Name resources using terraform.workspace.

Avoid Workspaces for enterprise production environments.

Never destroy from the wrong workspace.

---

# Common Mistakes

Applying in wrong workspace.

Destroying wrong environment.

Using local backend.

Assuming workspace duplicates code.

Deleting resources manually from AWS.

Forgetting to verify workspace before Apply.

---

# Interview Questions

## Q1. What is a Terraform Workspace?

### Answer

A Workspace is an isolated copy of Terraform State that allows the same Terraform code to manage multiple environments independently.

---

## Q2. Does Workspace duplicate Terraform code?

### Answer

No.

Workspace only creates a separate State file.

Terraform configuration files remain exactly the same.

---

## Q3. Why use Workspaces?

### Answer

To manage Development, Stage, and Production environments using the same Terraform code while keeping each environment's infrastructure state isolated.

---

## Q4. What changes between Workspaces?

### Answer

Only the Terraform State changes.

The configuration files remain unchanged.

---

## Q5. Can two Workspaces manage the same resource?

### Answer

No.

Each workspace maintains its own independent state. Managing the same resource from multiple workspaces can cause conflicts and should be avoided.

---

## Q6. Why did your S3 bucket contain env:/dev/dev?

### Answer

Terraform automatically prefixes workspace state with env:/<workspace>/. Since our backend key already contained "dev/", the resulting path became env:/dev/dev/terraform.tfstate.

---

## Q7. Can you delete the default Workspace?

### Answer

No.

Terraform always keeps the default workspace.

---

## Q8. Should large enterprises use Workspaces for Production?

### Answer

Usually no.

Large organizations generally prefer separate environment folders, separate backends, and dedicated CI/CD pipelines for better isolation and governance.

---

## Q9. What happens if you run terraform apply in the wrong workspace?

### Answer

Terraform will create or modify infrastructure for that workspace's state, potentially deploying resources into the wrong environment.

---

## Q10. What is terraform.workspace?

### Answer

terraform.workspace is a built-in variable that returns the name of the currently selected workspace. It is commonly used to generate environment-specific resource names and configurations.

---

# Key Takeaways

✔ A Workspace isolates Terraform State, not Terraform code.

✔ Multiple environments can share the same Terraform configuration.

✔ Always verify the active workspace before planning, applying, or destroying infrastructure.

✔ Backend and Workspaces work together to provide isolated remote state.

✔ Understanding Workspaces is essential for managing multiple environments efficiently.