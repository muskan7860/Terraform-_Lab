# Phase 14 - Terraform Variables & tfvars (Complete Deep Dive)

---

# Goal

Infrastructure should never contain hardcoded values.

Imagine you want to deploy the same infrastructure for:

- Development
- Stage
- Production

Should you modify the code every time?

Absolutely not.

Terraform Variables solve this problem.

By the end of this document, you will understand:

- Why Variables are needed
- Types of Variables
- Input Variables
- Local Variables
- Output Variables
- terraform.tfvars
- *.auto.tfvars
- Variable Validation
- Variable Precedence
- Environment Variables
- Sensitive Variables
- Best Practices
- Enterprise Standards
- Troubleshooting
- Interview Questions with Answers

---

# Why Do We Need Variables?

Suppose your EC2 resource looks like this.

```hcl
resource "aws_instance" "web" {

  ami           = "ami-07e5ce642bbc48c0d"

  instance_type = "t3.micro"

}
```

Now Production needs

```
t3.large
```

Development needs

```
t3.micro
```

Stage needs

```
t3.small
```

Will you edit the code every time?

No.

Instead,

```
instance_type = var.instance_type
```

Now only the variable changes.

The code remains the same.

---

# What is a Variable?

A Variable is an input value provided to Terraform.

Think of Variables as placeholders.

Example

```
Name = _______
```

The blank space is filled at runtime.

---

# Types of Variables

Terraform has four important types.

1. Input Variables

2. Local Variables

3. Output Variables

4. Environment Variables

---

# Input Variables

These receive values from outside.

Example

```hcl
variable "instance_type" {

  type = string

}
```

Usage

```hcl
instance_type = var.instance_type
```

---

# Variable Components

Example

```hcl
variable "instance_type" {

  description = "EC2 Instance Type"

  type = string

  default = "t3.micro"

}
```

---

## Description

Helps other developers understand the purpose.

---

## Type

Defines the data type.

---

## Default

Makes the variable optional.

If omitted,

Terraform asks the user.

---

# Data Types

String

```hcl
type = string
```

Example

```
"t3.micro"
```

---

Number

```hcl
type = number
```

Example

```
2
```

---

Boolean

```hcl
type = bool
```

Example

```
true
```

---

List

```hcl
type = list(string)
```

Example

```
["subnet-1","subnet-2"]
```

---

Map

```hcl
type = map(string)
```

Example

```
{

Environment = "Dev"

Owner = "Muskan"

}
```

---

Object

Example

```hcl
type = object({

instance_type = string

disk_size = number

})
```

Used for complex configurations.

---

# Our Project Variables

We created variables for

```
Project Name

Environment

Region

CIDR

Subnet CIDR

Instance Type

Key Pair

Root Volume

```

Instead of hardcoding values.

---

# variables.tf

This file defines variables.

Example

```
variables.tf

↓

All Variable Definitions
```

---

# terraform.tfvars

This file assigns values.

Example

variables.tf

```
variable "instance_type" {}
```

terraform.tfvars

```
instance_type = "t3.micro"
```

---

# Why Separate Variables?

Code

↓

Reusable

Values

↓

Environment-specific

---

# Environment Example

Dev

```
instance_type = "t3.micro"
```

Stage

```
instance_type = "t3.small"
```

Production

```
instance_type = "t3.large"
```

Same Terraform code.

Different infrastructure.

---

# Our Project

We created

```
terraform.tfvars
```

to store values.

Terraform automatically loads this file.

No need to specify it manually.

---

# Custom tfvars File

Example

```
dev.tfvars

stage.tfvars

prod.tfvars

```

Run

```bash
terraform apply -var-file=dev.tfvars
```

---

# auto.tfvars

Terraform automatically loads

```
*.auto.tfvars
```

Example

```
dev.auto.tfvars
```

No command needed.

---

# Passing Variables Using CLI

Example

```bash
terraform apply \
-var="instance_type=t3.micro"
```

Useful for testing.

---

# Passing Variables Through Environment Variables

Terraform supports

```
TF_VAR_

```

Example

```bash
export TF_VAR_instance_type=t3.micro
```

Terraform automatically reads it.

Useful in CI/CD.

---

# Variable Validation

Example

```hcl
variable "instance_type" {

type = string

validation {

condition = contains(

["t3.micro","t3.small"],

var.instance_type

)

error_message = "Invalid Instance Type."

}

}
```

Stops invalid input.

---

# Sensitive Variables

Passwords

Secrets

Access Keys

should never be printed.

Example

```hcl
variable "db_password" {

sensitive = true

}
```

Terraform hides the value.

---

# Local Variables

Locals reduce repetition.

Without locals

```
terraform-megha-project-dev

terraform-megha-project-stage

terraform-megha-project-prod

```

Repeated everywhere.

---

With locals

```hcl
locals {

name = "${var.project_name}-${var.environment}"

}
```

Usage

```
local.name
```

Cleaner code.

---

# Our Project

We used

locals.tf

to generate

```
terraform-megha-project-dev

terraform-megha-project-stage

terraform-megha-project-prod

```

Automatically.

---

# Variable Precedence

Terraform follows a priority order.

Highest Priority

CLI

```
-var
```

↓

-var-file

↓

Environment Variable

↓

terraform.tfvars

↓

auto.tfvars

↓

Default Value

Lowest Priority

---

Example

variables.tf

```
default = "t2.micro"
```

terraform.tfvars

```
instance_type = "t3.micro"
```

CLI

```
terraform apply -var="instance_type=t3.large"
```

Terraform chooses

```
t3.large
```

Highest priority wins.

---

# Best Practices

Use variables for everything configurable.

Never hardcode

Region

CIDR

AMI

Instance Type

Environment

Use locals for repeated expressions.

Use tfvars for environment values.

Keep secrets outside tfvars.

Validate inputs.

Provide descriptions.

---

# Common Mistakes

Mistake

Hardcoding values.

Solution

Use Variables.

---

Mistake

Keeping passwords in Git.

Solution

Use

Secrets Manager

Vault

Environment Variables

---

Mistake

Using too many locals.

Solution

Use locals only for repeated calculations.

---

Mistake

No validation.

Solution

Always validate critical inputs.

---

# Troubleshooting

## Problem

Terraform asks for variable value.

Reason

No default.

No tfvars.

No CLI input.

---

Solution

Provide value.

---

## Problem

Unsupported argument.

Reason

Wrong variable name.

---

Solution

Verify spelling.

---

## Problem

Variable not used.

Terraform warns.

Delete unused variables.

---

## Problem

Wrong data type.

Example

```
instance_count = "two"
```

Expected

```
2
```

---

# Interview Questions

## Q1 What are Terraform Variables?

### Answer

Variables allow infrastructure code to be dynamic and reusable by accepting values at runtime instead of hardcoding them.

---

## Q2 Why use terraform.tfvars?

### Answer

To store environment-specific variable values separately from the infrastructure code.

---

## Q3 Difference between variables.tf and terraform.tfvars?

### Answer

variables.tf defines variables.

terraform.tfvars assigns values to those variables.

---

## Q4 What are Local Variables?

### Answer

Local Variables store calculated or repeated expressions to avoid duplication.

---

## Q5 Difference between Variables and Locals?

### Answer

Variables receive input from outside Terraform.

Locals are calculated internally within Terraform.

---

## Q6 What is Variable Validation?

### Answer

Validation checks user input before Terraform creates infrastructure, preventing invalid configurations.

---

## Q7 What are Sensitive Variables?

### Answer

Sensitive Variables hide confidential information like passwords, tokens, and API keys from Terraform output.

---

## Q8 What is Variable Precedence?

### Answer

Variable precedence determines which value Terraform uses when the same variable is defined in multiple places.

Priority:

CLI → var-file → Environment Variable → terraform.tfvars → auto.tfvars → Default.

---

## Q9 Can Terraform automatically load tfvars?

### Answer

Yes.

Terraform automatically loads:

- terraform.tfvars
- terraform.tfvars.json
- *.auto.tfvars
- *.auto.tfvars.json

---

## Q10 Why did our project use locals?

### Answer

We generated reusable names such as:

```
terraform-megha-project-dev
terraform-megha-project-stage
terraform-megha-project-prod
```

using `locals.tf`, avoiding duplication throughout the codebase.

---

# Real Project Flow

Project Started

↓

variables.tf

↓

terraform.tfvars

↓

locals.tf

↓

main.tf

↓

terraform plan

↓

Terraform substituted all variable values

↓

Infrastructure created

---

# Key Takeaways

✔ Variables make Terraform reusable.

✔ terraform.tfvars stores environment-specific values.

✔ Locals reduce repetition.

✔ Validation prevents incorrect deployments.

✔ Sensitive variables protect secrets.

✔ Understand variable precedence to predict which value Terraform will use.

✔ In production, secrets should come from secure systems such as AWS Secrets Manager, HashiCorp Vault, or CI/CD secret stores instead of being committed to Git.