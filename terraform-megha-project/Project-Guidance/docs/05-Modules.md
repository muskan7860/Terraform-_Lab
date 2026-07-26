# Phase 5 - Terraform Modules (Deep Dive)

---

# Goal

In this phase, we transformed our Terraform code from a monolithic structure into reusable modules.

Instead of writing EC2, VPC, Security Group, and Key Pair resources directly in `main.tf`, we created separate modules for each infrastructure component.

This follows Infrastructure as Code (IaC) best practices and makes the project scalable, reusable, and production-ready.

---

# What is a Terraform Module?

A Terraform module is a container for multiple Terraform resources that are used together.

Think of a module like a function in programming.

Instead of copying the same code repeatedly, you write it once and reuse it wherever required.

---

## Without Modules

Suppose you need three EC2 instances.

Many beginners write:

```
resource "aws_instance" "dev" {}

resource "aws_instance" "stage" {}

resource "aws_instance" "prod" {}
```

Problems:

- Duplicate code
- Hard to maintain
- Difficult to debug
- Easy to introduce inconsistencies

---

## With Modules

Create one reusable module.

```
module "ec2_dev" {}

module "ec2_stage" {}

module "ec2_prod" {}
```

The same code is reused with different input values.

---

# Why do we use Modules?

Modules solve many real-world problems.

Without modules:

❌ Duplicate code

❌ Maintenance nightmare

❌ Difficult collaboration

❌ Inconsistent infrastructure

With modules:

✅ Reusable

✅ Easy to maintain

✅ Standardized

✅ Easier to test

✅ Production ready

---

# Types of Modules

Terraform supports two types of modules.

## 1. Root Module

The directory where you run Terraform commands.

Example

```
terraform init

terraform plan

terraform apply
```

Current directory

```
infra-app/
```

This is your Root Module.

---

## 2. Child Module

Any module called using

```
module "name" {}
```

Example

```
modules/

vpc/

ec2/

keypair/

security-group/
```

These are Child Modules.

---

# Project Structure

```
terraform-megha-project

│

├── infra-app

│     main.tf

│     variables.tf

│

├── modules

│     ec2

│     security-group

│     vpc

│     keypair

│

└── backend
```

---

# Module Lifecycle

Terraform follows this sequence.

```
Terraform Start

↓

Read Root Module

↓

Find Module Blocks

↓

Download/Load Modules

↓

Read Variables

↓

Read Resources

↓

Dependency Graph

↓

Plan

↓

Apply

↓

State Update
```

---

# How Modules Work Internally

Suppose Root Module contains

```
module "ec2" {

source="./modules/ec2"

instance_type="t3.micro"

}
```

Terraform performs

Step 1

Locate module

↓

Step 2

Read variables.tf

↓

Step 3

Assign values

↓

Step 4

Read resources

↓

Step 5

Generate dependency graph

↓

Step 6

Create infrastructure

---

# Anatomy of a Module

Example

modules/ec2

```
modules

└── ec2

      main.tf

      variables.tf

      outputs.tf
```

Every module usually contains

main.tf

variables.tf

outputs.tf

README.md

---

# main.tf

Contains actual AWS resources.

Example

EC2

EBS

IAM Profile

Elastic IP

etc.

---

# variables.tf

Defines inputs.

Example

```
variable "instance_type" {}

variable "ami" {}

variable "subnet_id" {}
```

Modules never hardcode values.

---

# outputs.tf

Exports values.

Example

```
output "instance_id" {}

output "public_ip" {}
```

These outputs can be used by the Root Module or other modules.

---

# Module Inputs

Input Variables

↓

Configuration enters module

Example

```
instance_type

AMI

Tags

Subnet ID

Security Group ID
```

---

# Module Outputs

Module produces

Instance ID

Public IP

Private IP

Subnet ID

Security Group ID

VPC ID

---

# Visual Flow

```
Root Module

↓

Input Variables

↓

Child Module

↓

AWS Resources

↓

Outputs

↓

Root Module
```

---

# Why Variables are Important

Imagine instance type changes.

Without variables

Edit every file.

With variables

Change one value.

Entire infrastructure updates.

---

# Why Outputs are Important

Outputs allow one module to share information with another.

Example

VPC Module creates

```
VPC ID
```

Security Group Module needs

```
VPC ID
```

Instead of hardcoding

Use

```
module.vpc.vpc_id
```

---

# Module Dependencies

Terraform automatically detects dependencies.

Example

EC2 requires

Subnet

↓

Subnet requires

VPC

Terraform understands

```
VPC

↓

Subnet

↓

EC2
```

without manually defining execution order.

---

# Why Modules are Better than Copy-Paste

Copy-Paste

10 Projects

↓

Need bug fix

↓

Edit 10 projects

Modules

10 Projects

↓

Fix once

↓

All projects updated

---

# Benefits of Modules

✔ Reusability

✔ Maintainability

✔ Scalability

✔ Less duplication

✔ Easier testing

✔ Cleaner code

✔ Easier onboarding

✔ Team collaboration

✔ Version control

✔ Production standard

---

# Common Mistakes

Hardcoding values

Huge modules

Too many unrelated resources

No outputs

No variables

Copy-paste resources

Ignoring README

Not versioning modules

---

# Best Practices

One responsibility per module

Use variables

Export outputs

Keep modules small

Document every module

Version modules

Never hardcode environment values

Keep modules reusable

---

# Real Production Example

Company has

Development

Testing

Production

Each environment

Uses

```
EC2 Module

VPC Module

IAM Module

EKS Module

ALB Module

RDS Module
```

Same code

Different variables

---

# Our Modules

We created

```
modules/

vpc/

security-group/

keypair/

ec2/
```

Each module performs one responsibility.

Root module combines all modules together.

---

# Why did we create separate modules?

VPC changes rarely.

Security Group changes occasionally.

EC2 changes frequently.

Keeping them separate allows independent maintenance.

---

# Interview Questions

## Q1. What is a Terraform Module?

### Answer

A Terraform module is a reusable collection of Terraform resources that are grouped together to perform a specific task. Modules help reduce code duplication, improve maintainability, and standardize infrastructure creation.

---

## Q2. What is the difference between a Root Module and a Child Module?

### Answer

The Root Module is the directory from which Terraform commands are executed. A Child Module is any module that is called by the Root Module using a `module` block. The Root Module orchestrates the infrastructure, while Child Modules implement reusable components.

---

## Q3. Why are modules used?

### Answer

Modules are used to avoid code duplication, improve readability, simplify maintenance, promote code reuse, and make infrastructure deployment consistent across multiple environments.

---

## Q4. How do modules receive values?

### Answer

Modules receive values through input variables defined in `variables.tf`. The Root Module passes these values when calling the module.

---

## Q5. How do modules share information?

### Answer

Modules share information using outputs. A Child Module defines outputs in `outputs.tf`, and the Root Module accesses them using expressions like `module.vpc.vpc_id`.

---

## Q6. Can one module use another module's output?

### Answer

Yes. Outputs from one module can be passed as input variables to another module, allowing modules to work together without hardcoding values.

---

## Q7. Why should modules be small?

### Answer

Small modules are easier to understand, test, debug, and reuse. Each module should follow the Single Responsibility Principle and perform one well-defined task.

---

## Q8. Where are Terraform modules stored?

### Answer

Modules can be stored locally within the project, in a Git repository, in a Terraform Registry, or in private module registries used by organizations.

---

## Q9. What happens during `terraform init` when modules are present?

### Answer

Terraform identifies all module blocks, downloads or loads the modules from their source locations, initializes providers, and prepares the dependency graph before any planning or deployment.

---

## Q10. Explain the module architecture used in your project.

### Answer

Our project uses a Root Module (`infra-app`) to coordinate deployment. Infrastructure components such as VPC, Security Group, Key Pair, and EC2 are implemented as Child Modules. Each Child Module has its own `main.tf`, `variables.tf`, and `outputs.tf`. Environment-specific values are passed from the Root Module, making the modules reusable across development, staging, and production environments.