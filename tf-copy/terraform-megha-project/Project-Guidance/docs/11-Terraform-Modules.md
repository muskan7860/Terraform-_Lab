# Phase 11 - Terraform Modules (Complete Deep Dive)

---

# Goal

In this phase, we learned how to write modular Terraform code using reusable modules instead of placing everything inside one large `main.tf` file.

By the end of this phase, you will understand:

- What a Terraform Module is
- Why Modules are important
- Root Module vs Child Module
- Module directory structure
- Input Variables
- Output Variables
- Module Reusability
- Module Dependencies
- How our project uses Modules
- Best Practices
- Enterprise Standards
- Common Mistakes
- Troubleshooting
- Interview Questions with Detailed Answers

---

# What is a Terraform Module?

A Terraform Module is simply a container for Terraform configuration files.

Whenever Terraform executes a folder containing `.tf` files, that folder itself is called a Module.

Every Terraform project has at least one module.

That module is called the **Root Module**.

---

# Why Do We Need Modules?

Imagine writing a project like this:

```

main.tf

resource "aws_vpc"

resource "aws_subnet"

resource "aws_route_table"

resource "aws_route_table_association"

resource "aws_security_group"

resource "aws_instance"

resource "aws_key_pair"

resource "aws_eip"

resource "aws_iam_role"

resource "aws_s3_bucket"

resource "aws_lb"

resource "aws_autoscaling_group"

...

```

After 500–1000 lines, the file becomes very difficult to understand and maintain.

Problems include:
- Difficult debugging
- Difficult maintenance
- Code duplication
- Hard collaboration
- Higher chance of mistakes

Modules solve these problems by separating infrastructure into logical components.

---

# Think Like LEGO Blocks

Each module performs one responsibility.

```

Project

│

├── VPC Module

├── Security Group Module

├── Key Pair Module

├── EC2 Module

├── Database Module

├── Load Balancer Module

└── Monitoring Module

```

Each block can be reused independently.

---

# Root Module

The folder where you execute:

```bash
terraform init
terraform plan
terraform apply
```

is called the Root Module.

Example:

```

infra-app/

main.tf

variables.tf

outputs.tf

terraform.tfvars

modules/

```

Everything starts from here.

---

# Child Module

Every folder inside `modules/` is called a Child Module.

Example:

```

modules/

vpc/

ec2/

security-group/

keypair/

```

Each child module contains its own Terraform code.

---

# Our Project Structure

```

terraform-megha-project/

│

├── backend/

│

├── infra-app/

│   │

│   ├── main.tf

│   ├── variables.tf

│   ├── outputs.tf

│   ├── provider.tf

│   ├── terraform.tfvars

│   │

│   └── modules/

│

├── vpc/

├── ec2/

├── security-group/

└── keypair/

```

This is a clean enterprise structure.

---

# Module Responsibility

Each module should perform one responsibility only.

### VPC Module

Creates:

- VPC
- Internet Gateway
- Route Table
- Public Subnet
- Route Table Association

---

### Security Group Module

Creates:

- Security Group
- SSH Rule
- HTTP Rule
- Outbound Rule

---

### Key Pair Module

Creates:

- AWS Key Pair

---

### EC2 Module

Creates:

- EC2 Instance

---

# Why Separate Modules?

Because each module can be reused.

Example:

Today:

```

1 VPC

1 EC2

```

Tomorrow:

```

5 VPCs

50 EC2s

```

No code rewrite required.

---

# How Root Module Calls Child Module

Example:

```hcl
module "vpc" {
  source = "./modules/vpc"

  cidr_block = var.vpc_cidr
}
```

Terraform enters the folder and executes everything inside it.

---

# Module Source

Terraform loads modules using the `source` argument.

Example:

```hcl
source = "./modules/vpc"
```

Local Module

---

GitHub Module

```hcl
source = "github.com/company/module"
```

---

Terraform Registry

```hcl
source = "terraform-aws-modules/vpc/aws"
```

---

# Module Input Variables

Modules should never hardcode values.

Wrong:

```hcl
cidr_block = "10.0.0.0/16"
```

Correct:

```hcl
variable "vpc_cidr" {}
```

Then:

```hcl
cidr_block = var.vpc_cidr
```

Now the same module can create many VPCs.

---

# Module Outputs

Modules expose values using outputs.

Example:

```
output "vpc_id" {
 value = aws_vpc.main.id
}
```

Root Module can use:

```
module.vpc.vpc_id
```

---

# Module Dependency

Our project dependency looks like this:

```

Key Pair

↓

Security Group

↓

VPC

↓

Subnet

↓

EC2

```

Terraform automatically understands this dependency through references.

---

# How EC2 Receives VPC Information

EC2 needs:

- Security Group ID
- Subnet ID
- Key Pair

These are passed as module outputs.

Example:

```
module.vpc.public_subnet_id

↓

module.ec2
```

No hardcoding.

---

# Benefits of Modules

- Reusable
- Easy Maintenance
- Smaller Files
- Better Readability
- Team Collaboration
- Version Control
- Easier Testing

---

# Common Mistakes

### Mistake 1

Putting everything inside one main.tf

Result:

Huge unreadable file.

---

### Mistake 2

Hardcoding IDs

Wrong:

```
subnet_id = "subnet-12345"
```

Correct:

```
subnet_id = module.vpc.public_subnet_id
```

---

### Mistake 3

Duplicate Code

Copy-paste infrastructure.

Instead:

Reuse modules.

---

### Mistake 4

No Outputs

Without outputs, modules cannot communicate.

---

### Mistake 5

Using variables inside another module directly

Wrong:

```
var.vpc_id
```

Correct:

```
module.vpc.vpc_id
```

---

# Enterprise Best Practices

- One responsibility per module.
- Keep modules small.
- Never hardcode values.
- Always define input variables.
- Always expose required outputs.
- Store reusable modules in Git.
- Version modules.
- Write README for every module.
- Add examples for module usage.
- Test modules independently.

---

# Troubleshooting

## Problem

Module not found.

### Error

```
Module not installed.
```

### Solution

Run:

```bash
terraform init
```

---

## Problem

Unsupported argument.

### Cause

Passing an input variable not defined in the module.

### Solution

Declare the variable inside the child module.

---

## Problem

Unsupported attribute.

### Cause

Trying to access an output that does not exist.

### Solution

Define the output inside the module.

---

## Problem

Reference to undeclared module.

### Cause

Using the wrong module name.

### Solution

Verify the module block name in `main.tf`.

---

# Real Project Flow

```
terraform init

↓

Load Modules

↓

Validate Variables

↓

Create Dependency Graph

↓

Plan Resources

↓

Apply Resources

↓

Store State
```

---

# Interview Questions

## Q1. What is a Terraform Module?

### Answer

A Terraform Module is a reusable container of Terraform configuration files used to organize and manage infrastructure code.

---

## Q2. What is the Root Module?

### Answer

The directory where Terraform commands (`init`, `plan`, `apply`) are executed is called the Root Module.

---

## Q3. What is a Child Module?

### Answer

A Child Module is any module called by another module using the `module` block.

---

## Q4. Why use Modules?

### Answer

Modules improve reusability, readability, maintainability, collaboration, and reduce code duplication.

---

## Q5. Can a Module call another Module?

### Answer

Yes. Modules can be nested, although excessive nesting should be avoided for simplicity.

---

## Q6. How do Modules communicate?

### Answer

Using Input Variables and Output Values.

One module exposes an output, and another module consumes it.

---

## Q7. Where are reusable modules usually stored?

### Answer

Reusable modules are commonly stored in:
- Git repositories
- Terraform Registry
- Internal module registries used by organizations

---

## Q8. What happens if you change a module?

### Answer

Terraform detects changes during `terraform plan` and applies only the required infrastructure updates.

---

## Q9. Why shouldn't IDs be hardcoded?

### Answer

Hardcoded IDs reduce portability and reusability. Outputs from one module should be passed into another module instead.

---

## Q10. Explain your project's module structure.

### Answer

Our project contains separate modules for:
- VPC
- Security Group
- Key Pair
- EC2

The Root Module orchestrates these child modules by passing variables and consuming outputs, making the infrastructure modular, reusable, and easy to maintain.

---

# Key Takeaways

✔ Modules make Terraform code reusable and maintainable.

✔ The Root Module controls the deployment.

✔ Child Modules handle specific infrastructure components.

✔ Variables pass inputs into modules.

✔ Outputs expose values from modules.

✔ Modules communicate using inputs and outputs rather than hardcoded values.

✔ A modular structure is the standard approach used in production DevOps environments.