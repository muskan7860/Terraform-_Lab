# Phase 15 - Terraform Dependency Graph & Resource Lifecycle (Complete Deep Dive)

---

# Goal

Terraform is much more than simply reading `.tf` files from top to bottom.

It first analyzes every resource, understands their relationships, creates a dependency graph, and then executes resources in the correct order.

Understanding this process is critical for troubleshooting complex infrastructure.

By the end of this chapter, you will understand:

- What is a Dependency Graph
- How Terraform determines execution order
- Implicit Dependencies
- Explicit Dependencies (`depends_on`)
- Resource Lifecycle
- Create, Update, Replace, Destroy
- Lifecycle Meta Arguments
- Parallel Resource Creation
- Resource Replacement
- Destroy Order
- Enterprise Best Practices
- Troubleshooting
- Interview Questions with Detailed Answers

---

# Why Dependency Management is Required?

Imagine the following infrastructure.

EC2

↓

Subnet

↓

VPC

Can Terraform create the EC2 first?

No.

The EC2 needs a subnet.

The subnet needs a VPC.

Therefore Terraform must understand these relationships automatically.

---

# Real Life Analogy

Building a house.

Can you build walls before the foundation?

No.

Can you install windows before walls?

No.

Terraform follows exactly the same logic.

---

# What is Terraform Dependency Graph?

A Dependency Graph is an internal Directed Acyclic Graph (DAG) that Terraform creates before executing any resources.

The graph defines:

- Resource relationships
- Execution order
- Parallel execution opportunities

Terraform does NOT execute files from top to bottom.

It executes based on this graph.

---

# Our Project Dependency Graph

```
VPC
 │
 ├── Internet Gateway
 │
 ├── Public Subnet
 │      │
 │      └── Route Table Association
 │
 └── Security Group
          │
          └── EC2 Instance
```

Terraform understood this automatically.

---

# What Happens During terraform apply?

Step 1

Read all Terraform files.

↓

Step 2

Build Dependency Graph.

↓

Step 3

Validate Configuration.

↓

Step 4

Query AWS.

↓

Step 5

Compare State.

↓

Step 6

Create Execution Plan.

↓

Step 7

Execute Resources.

---

# Implicit Dependency

Terraform automatically detects dependencies when one resource references another.

Example

```hcl
resource "aws_subnet" "public" {

  vpc_id = aws_vpc.main.id

}
```

Terraform understands:

```
Subnet

depends on

VPC
```

No additional configuration is required.

---

# Our Project

Example

```hcl
resource "aws_instance" "ec2" {

  subnet_id = module.vpc.public_subnet_id

}
```

Terraform automatically creates

VPC

↓

Subnet

↓

EC2

---

# Explicit Dependency

Sometimes Terraform cannot determine the dependency.

Example

```hcl
depends_on = [

module.security_group

]
```

Now Terraform waits until the Security Group is created.

---

# When Should depends_on Be Used?

Only when Terraform cannot infer the relationship.

Examples

Null resources

Provisioners

External APIs

Scripts

IAM propagation

Custom resources

---

# Avoid Overusing depends_on

Many beginners write

```hcl
depends_on = [

module.vpc

]
```

for everything.

This is incorrect.

Terraform already understands most dependencies automatically.

Adding unnecessary dependencies slows deployments.

---

# Terraform Graph Command

Terraform can display the dependency graph.

Command

```bash
terraform graph
```

You can visualize it using Graphviz.

This is useful for debugging complex projects.

---

# Parallel Resource Creation

Suppose your project contains

```
S3 Bucket

IAM Role

CloudWatch Log Group
```

None depend on each other.

Terraform creates all three simultaneously.

Result

Faster deployments.

---

# Example

```
Resource A

Resource B

Resource C
```

No dependency.

Terraform creates all together.

---

# Sequential Creation

Now suppose

```
VPC

↓

Subnet

↓

EC2
```

Terraform creates

Step 1

VPC

↓

Step 2

Subnet

↓

Step 3

EC2

---

# Resource Lifecycle

Every Terraform resource passes through one of four operations.

Create

Update

Replace

Destroy

---

# Create

Resource does not exist.

Terraform creates it.

Example

```
terraform apply
```

Output

```
+ create
```

---

# Update

Resource already exists.

Only mutable properties changed.

Example

```
Tag changed

Instance Name changed

```

Output

```
~ update
```

---

# Replace

Some properties cannot be modified.

Terraform destroys the old resource and creates a new one.

Example

Changing

AMI

Subnet

Availability Zone

may require replacement.

Output

```
-/+
```

Destroy

↓

Create

---

# Destroy

Resource removed from configuration.

Output

```
- destroy
```

---

# Resource Lifecycle Flow

```
Configuration

↓

Plan

↓

Create

↓

Update

↓

Replace

↓

Destroy
```

---

# Lifecycle Meta Arguments

Terraform provides lifecycle controls.

```
lifecycle {

...

}
```

---

# create_before_destroy

Default behavior

Destroy

↓

Create

Downtime occurs.

---

Using

```hcl
lifecycle {

create_before_destroy = true

}
```

Terraform creates the new resource first.

Then destroys the old one.

Zero or minimal downtime.

---

# prevent_destroy

Production databases should never be accidentally deleted.

Example

```hcl
lifecycle {

prevent_destroy = true

}
```

Now

```
terraform destroy
```

fails.

Very useful for

Production RDS

S3 Buckets

Critical Infrastructure

---

# ignore_changes

Suppose AWS automatically changes

Tags

Metadata

Monitoring

Terraform normally detects drift.

Sometimes we intentionally ignore those fields.

Example

```hcl
lifecycle {

ignore_changes = [

tags

]

}
```

Terraform ignores tag changes.

---

# replace_triggered_by

Introduced for advanced replacement logic.

Example

Replace EC2 when Launch Template changes.

---

# Resource Taint

Older Terraform versions

```
terraform taint

```

Marked a resource for recreation.

Modern Terraform recommends

```
terraform apply -replace

```

Example

```bash
terraform apply -replace=module.ec2.aws_instance.ec2[0]
```

Only that resource is recreated.

---

# Destroy Order

Terraform destroys resources in reverse dependency order.

Example

Current

```
EC2

↓

Subnet

↓

VPC
```

Destroy

```
EC2

↓

Subnet

↓

VPC
```

Reverse order.

This prevents dependency failures.

---

# Our Project Lifecycle

Apply

↓

Create VPC

↓

Create IGW

↓

Create Route Table

↓

Create Subnet

↓

Create Security Group

↓

Create Key Pair

↓

Create EC2

Destroy

↓

Destroy EC2

↓

Destroy Security Group

↓

Destroy Route Table Association

↓

Destroy Route Table

↓

Destroy Subnet

↓

Destroy Internet Gateway

↓

Destroy VPC

---

# Enterprise Best Practices

Use implicit dependencies whenever possible.

Avoid unnecessary depends_on.

Protect production resources using prevent_destroy.

Use create_before_destroy for high availability.

Use ignore_changes carefully.

Understand which resource changes require replacement.

Always review terraform plan before apply.

---

# Common Mistakes

Mistake

Using depends_on everywhere.

Result

Slow execution.

---

Mistake

Deleting dependencies manually in AWS.

Result

Terraform State Drift.

---

Mistake

Not understanding replacement.

Result

Unexpected downtime.

---

Mistake

Destroying Production resources accidentally.

Solution

prevent_destroy.

---

# Troubleshooting

## Problem

Terraform creates resources in wrong order.

Reason

Missing dependency.

Solution

Check resource references.

Use depends_on only if necessary.

---

## Problem

Terraform replaces EC2 unexpectedly.

Reason

Immutable property changed.

Example

AMI

Subnet

Availability Zone

---

## Problem

Circular Dependency

Example

A depends on B

B depends on A

Terraform cannot build the graph.

Solution

Remove unnecessary dependency.

---

## Problem

Slow apply.

Reason

Too many explicit dependencies.

Remove unnecessary depends_on.

---

# Interview Questions

## Q1 What is a Terraform Dependency Graph?

### Answer

Terraform Dependency Graph is an internal Directed Acyclic Graph (DAG) that represents resource relationships and determines the order in which resources are created, updated, or destroyed.

---

## Q2 Does Terraform execute files sequentially?

### Answer

No.

Terraform first builds a dependency graph and then executes resources according to dependencies, not file order.

---

## Q3 What is an Implicit Dependency?

### Answer

An implicit dependency occurs when one resource references another resource's attribute.

Example:

```hcl
vpc_id = aws_vpc.main.id
```

Terraform automatically detects the dependency.

---

## Q4 What is an Explicit Dependency?

### Answer

An explicit dependency is manually defined using `depends_on` when Terraform cannot automatically infer the relationship.

---

## Q5 When should depends_on be used?

### Answer

Only when Terraform cannot determine the dependency automatically, such as with provisioners, external scripts, or IAM propagation delays.

---

## Q6 What is create_before_destroy?

### Answer

It instructs Terraform to create the replacement resource before destroying the existing one, reducing downtime.

---

## Q7 What is prevent_destroy?

### Answer

It prevents Terraform from accidentally deleting critical resources such as production databases or storage buckets.

---

## Q8 What is ignore_changes?

### Answer

It tells Terraform to ignore changes to specific resource attributes during planning and applying.

---

## Q9 Why did Terraform create the VPC before the EC2 in our project?

### Answer

Because the EC2 instance referenced the subnet, the subnet referenced the VPC, and Terraform automatically built the dependency graph to ensure the correct creation order.

---

## Q10 Why does Terraform destroy resources in reverse order?

### Answer

To avoid dependency violations. Dependent resources must be removed before the resources they depend on.

---

# Real Project Mapping

Our infrastructure followed this dependency chain:

```
VPC
│
├── Internet Gateway
│
├── Route Table
│
├── Public Subnet
│
├── Route Table Association
│
├── Security Group
│
├── Key Pair
│
└── EC2 Instance
```

Terraform automatically determined this graph without requiring explicit `depends_on` because the resource references defined the dependencies.

---

# Key Takeaways

✔ Terraform executes resources based on a dependency graph, not file order.

✔ Most dependencies are detected automatically through resource references.

✔ Use `depends_on` only when Terraform cannot infer the relationship.

✔ Resources move through the lifecycle: Create → Update → Replace → Destroy.

✔ Lifecycle meta-arguments such as `create_before_destroy`, `prevent_destroy`, and `ignore_changes` provide additional control over infrastructure changes.

✔ Understanding the dependency graph is essential for debugging plans, preventing downtime, and designing reliable infrastructure.