# Phase 13 - Terraform Workspaces (Complete Deep Dive)

---

# Goal

Terraform Workspaces allow us to manage multiple environments using the same Terraform code while keeping their state files separate.

By the end of this document you will understand:

- What Terraform Workspaces are
- Why Workspaces are needed
- Default Workspace
- Creating Workspaces
- Selecting Workspaces
- Deleting Workspaces
- Workspace State Isolation
- Workspaces with Remote Backend
- Workspaces with S3
- Workspaces in Our Project
- Common Mistakes
- Troubleshooting
- Enterprise Best Practices
- Interview Questions with Detailed Answers

---

# What is a Terraform Workspace?

A Terraform Workspace is an isolated state environment.

It allows the same Terraform code to manage multiple independent infrastructures.

Think of it like creating multiple copies of the same blueprint.

Example

One code

↓

Three environments

```

Terraform Code

↓

DEV

↓

STAGE

↓

PROD

```

Each environment has its own State File.

---

# Why Do We Need Workspaces?

Suppose we only have one workspace.

```

terraform apply

```

creates

```

EC2

VPC

Subnet

```

Now we want another environment.

Without workspaces,

Terraform thinks

"I already created these resources."

Instead of creating a second infrastructure,

it updates the first one.

Not what we want.

---

# Solution

Create separate workspaces.

```

default

dev

stage

prod

```

Each workspace has

Independent State

Independent Infrastructure

Independent Outputs

Independent Lifecycle

---

# Real Life Analogy

Imagine one architect designing houses.

Same blueprint

↓

House A

↓

House B

↓

House C

Each house is separate.

Terraform Workspaces work exactly the same way.

---

# Default Workspace

Whenever Terraform starts,

it automatically creates

```

default

```

This workspace always exists.

You cannot delete it.

---

# List Workspaces

Command

```bash
terraform workspace list
```

Example

```

* default

dev

stage

prod

```

The *

means

Current Workspace.

---

# Current Workspace

Check

```bash
terraform workspace show
```

Example

```

dev

```

---

# Create Workspace

Command

```bash
terraform workspace new dev
```

Terraform creates

New State

New Infrastructure

Nothing is copied from default.

---

# Switch Workspace

```bash
terraform workspace select stage
```

Output

```

Switched to workspace "stage"

```

Now all Terraform commands operate only on Stage.

---

# Delete Workspace

```

terraform workspace delete dev

```

Rules

Cannot delete current workspace.

Cannot delete workspace with resources until they are destroyed.

---

# State Isolation

This is the most important concept.

Suppose

DEV

contains

```

EC2

VPC

```

Stage contains

```

Nothing

```

Running

```

terraform plan

```

inside Stage

shows

```

8 resources to create

```

because Stage has its own State.

Terraform cannot see DEV State.

---

# Workspace Flow

```

Workspace

↓

State

↓

Infrastructure

```

Each workspace owns

its own state.

---

# Local Backend Example

```

terraform.tfstate.d/

↓

dev/

terraform.tfstate

↓

stage/

terraform.tfstate

↓

prod/

terraform.tfstate

```

Each folder stores a separate State.

---

# Remote Backend Example

Our project uses S3.

Instead of local folders,

Terraform stores separate objects.

Example

```

dev

↓

dev/terraform.tfstate

```

```

stage

↓

stage/terraform.tfstate

```

```

prod

↓

prod/terraform.tfstate

```

---

# Our Project Backend

We configured

```

backend "s3" {}

```

Then

```

dev.hcl

```

contained

```

bucket

key

region

lock table

```

Terraform automatically handled

workspace-specific State.

---

# What Happened in Our Project?

We created

```

dev

stage

prod

```

Then

Terraform created

different State files

inside S3.

Later

we accidentally switched

between

default

dev

stage

without realizing.

Result

Terraform appeared to "lose"

resources.

Actually

it was simply reading another workspace.

---

# Why Did We See

env:/stage/stage/terraform.tfstate ?

Good question.

Terraform automatically prefixes the State path

when using named workspaces.

Suppose backend key is

```

stage/terraform.tfstate

```

Current workspace

```

stage

```

Terraform stores

```

env:/stage/stage/terraform.tfstate

```

The first

```

stage

```

is Workspace.

The second

```

stage

```

comes from backend key.

---

# Another Example

Workspace

```

dev

```

Backend Key

```

dev/terraform.tfstate

```

Terraform stores

```

env:/dev/dev/terraform.tfstate

```

This confused us during cleanup.

---

# Workspace Variables

Terraform exposes

```

terraform.workspace

```

Example

```

resource "aws_instance" "ec2" {

tags = {

Environment = terraform.workspace

}

}

```

Current Workspace

```

prod

```

Tag becomes

```

Environment=prod

```

Automatically.

---

# Workspace-based Naming

Example

```

Name = "ec2-${terraform.workspace}"

```

Result

```

ec2-dev

```

```

ec2-stage

```

```

ec2-prod

```

No duplicate names.

---

# Workspace Lifecycle

```

Create Workspace

↓

Switch Workspace

↓

terraform apply

↓

Resources Created

↓

State Stored

↓

Switch Workspace

↓

Repeat

```

---

# Does Workspace Copy Resources?

No.

Every workspace starts empty.

Terraform never copies infrastructure.

---

# Workspace Outputs

Outputs belong to that workspace only.

DEV

Public IP

```

3.110.x.x

```

Stage

Public IP

```

3.111.x.x

```

Completely independent.

---

# Common Mistakes

Mistake

Forgetting current workspace.

Result

Deploying Production into DEV.

---

Mistake

Destroying wrong workspace.

Result

Production deleted.

Always verify

```

terraform workspace show

```

before

apply

or

destroy.

---

Mistake

Using same naming convention.

Example

Every EC2 named

```

web-server

```

Instead

```

web-dev

web-stage

web-prod

```

---

Mistake

Deleting AWS resources manually.

Workspace State still thinks

Resources exist.

Creates State Drift.

---

# Troubleshooting

## Problem

Workspace not found

Example

```

Workspace "dev" doesn't exist

```

Solution

```

terraform workspace new dev

```

---

## Problem

No State Found

Reason

Workspace has never been applied.

Solution

Run

```

terraform apply

```

---

## Problem

terraform destroy destroys nothing

Reason

Current workspace State is empty.

Verify

```

terraform workspace show

terraform state list

```

---

## Problem

Wrong infrastructure shown

Reason

Wrong workspace selected.

Switch

```

terraform workspace select dev

```

---

# Enterprise Best Practices

Never use default workspace for production.

Use dedicated workspaces.

Always verify workspace before Apply.

Separate backend configurations.

Separate tfvars.

Use CI/CD validation.

Protect Production workspace.

Use naming convention including workspace.

---

# Our Project Flow

Created Backend

↓

Created DEV

↓

Applied DEV

↓

Created STAGE

↓

Applied STAGE

↓

Created PROD

↓

Applied PROD

↓

Verified State

↓

Destroyed Resources

↓

Cleaned Backend

---

# Interview Questions

## Q1 What is a Terraform Workspace?

### Answer

A Terraform Workspace is an isolated state environment that allows multiple infrastructures to be managed using the same Terraform configuration.

---

## Q2 Why use Workspaces?

### Answer

To manage multiple environments such as Development, Stage, and Production while keeping their State files separate.

---

## Q3 Does each Workspace have its own State?

### Answer

Yes.

Each workspace maintains an independent Terraform State.

---

## Q4 Can one Workspace access another Workspace's resources?

### Answer

No.

Terraform only reads the State associated with the currently selected workspace.

---

## Q5 How do you check the current Workspace?

### Answer

```

terraform workspace show

```

---

## Q6 How do you list Workspaces?

### Answer

```

terraform workspace list

```

---

## Q7 Can the default Workspace be deleted?

### Answer

No.

Terraform always keeps the default workspace.

---

## Q8 Why did our S3 bucket contain paths like env:/stage/stage/terraform.tfstate?

### Answer

Terraform automatically prefixes remote state paths with the workspace name (`env:/stage/`) when using named workspaces. Since our backend key was also `stage/terraform.tfstate`, both names appeared in the final S3 object path.

---

## Q9 What happens if you run destroy in the wrong Workspace?

### Answer

Terraform only destroys the infrastructure managed by the currently selected workspace. If the selected workspace has no state, it reports "No changes. No objects need to be destroyed."

---

## Q10 What is the difference between using Workspaces and separate directories?

### Answer

Workspaces separate only the Terraform State while sharing the same configuration.

Separate directories provide complete isolation, allowing different code, variables, modules, and backends for each environment.

Large enterprise environments often prefer separate directories or repositories for production because they provide stronger isolation and reduce operational risk.

---

# Key Takeaways

✔ Workspaces isolate Terraform State, not Terraform code.

✔ The same configuration can manage multiple environments.

✔ Each workspace has its own State file.

✔ Always verify the current workspace before running `plan`, `apply`, or `destroy`.

✔ Named workspaces automatically modify the State path in remote backends.

✔ Workspaces are useful for simple multi-environment projects, while larger organizations often use separate directories or repositories for stricter environment isolation.