# Phase 4 - Terraform Project Structure

---

# Goal

In this phase we organized our Terraform project using an industry-standard folder structure.

Instead of writing every resource in one file, we divided the infrastructure into reusable modules and environment-specific configurations.

This makes the project scalable, maintainable, reusable, and suitable for real production environments.

---

# Why do we need a proper folder structure?

Suppose we keep everything inside one file.

main.tf

It contains

VPC

Subnet

Security Group

EC2

IAM

Route Table

Load Balancer

Auto Scaling

RDS

S3

CloudFront

Lambda

API Gateway

EKS

CloudWatch

Soon the file becomes thousands of lines long.

Problems

❌ Difficult to understand

❌ Difficult to debug

❌ Difficult to maintain

❌ Cannot reuse code

❌ Team collaboration becomes difficult

Instead, we organize the project into modules.

---

# Final Project Structure

terraform-megha-project/

├── backend/
│   ├── backend.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── main.tf
│   ├── terraform.tfvars
│   └── modules/
│       ├── s3/
│       └── dynamodb/
│
├── infra-app/
│   ├── backend.tf
│   ├── provider.tf
│   ├── versions.tf
│   ├── variables.tf
│   ├── locals.tf
│   ├── outputs.tf
│   ├── data.tf
│   ├── terraform.tfvars
│   └── main.tf
│
├── backend-config/
│   ├── dev.hcl
│   ├── stage.hcl
│   └── prod.hcl
│
├── modules/
│   ├── vpc/
│   ├── subnet/
│   ├── security-group/
│   ├── keypair/
│   └── ec2/
│
├── docs/
│
└── README.md

---

# High Level Architecture

                     Terraform Project

                            │

        ┌───────────────────┼──────────────────┐

        │                   │                  │

     Backend           Infra Project        Modules

        │                   │                  │

        │                   │                  │

 S3 + DynamoDB       Main Configuration   Reusable Components

---

# Backend Folder

Purpose

This folder creates the backend infrastructure.

Resources

S3 Bucket

DynamoDB Table

Versioning

Encryption

Public Access Block

This folder is executed only once.

Reason

Every Terraform project requires one backend.

After backend creation we rarely modify it.

---

# Why backend is separated?

Suppose backend and application resources are together.

Terraform starts.

Terraform wants backend.

Backend doesn't exist.

Terraform cannot continue.

This creates a chicken-and-egg problem.

Therefore backend is always created first.

After backend creation,

all remaining Terraform projects use it.

---

# Infra-App Folder

This is the main infrastructure folder.

It does not create backend.

Instead,

it uses backend.

Example

terraform {

backend "s3" {}

}

Backend values come from

dev.hcl

stage.hcl

prod.hcl

This folder contains

Provider

Variables

Locals

Outputs

Data Sources

Module Calls

---

# Modules Folder

Modules contain reusable Terraform code.

Instead of writing EC2 repeatedly,

we create

modules/ec2

Now

Development

Stage

Production

all use

same module.

Benefits

✔ Less code

✔ Easy maintenance

✔ Reusable

✔ Standardized

---

# VPC Module

Responsible for

Creating VPC

CIDR

DNS Support

DNS Hostnames

Output

VPC ID

---

# Subnet Module

Responsible for

Public Subnet

Private Subnet

CIDR

Availability Zone

Route Table Association

Outputs

Subnet IDs

---

# Security Group Module

Responsible for

SSH Rule

HTTP Rule

HTTPS Rule

Outbound Rules

Outputs

Security Group ID

---

# Key Pair Module

Responsible for

Creating AWS Key Pair

Uploading Public Key

Output

Key Name

---

# EC2 Module

Responsible for

EC2 Instance

AMI

Instance Type

User Data

Tags

Volume

Outputs

Instance ID

Private IP

Public IP

---

# Backend Config Folder

Contains

dev.hcl

stage.hcl

prod.hcl

Example

dev.hcl

bucket

key

region

dynamodb table

Every environment uses a different state location.

---

# Docs Folder

Contains

Project Documentation

Architecture

Interview Questions

Troubleshooting

Best Practices

Deployment Guide

README

Purpose

Anyone can understand the project without asking the developer.

---

# What happens when we run terraform init?

Terraform starts.

↓

Reads backend.tf

↓

Reads backend configuration file

↓

Connects to S3

↓

Downloads state

↓

Initializes provider

↓

Downloads modules

↓

Ready

---

# What happens when we run terraform plan?

Terraform

↓

Reads Variables

↓

Reads Data Sources

↓

Loads Modules

↓

Builds Dependency Graph

↓

Reads State

↓

Reads AWS Infrastructure

↓

Creates Execution Plan

---

# What happens during terraform apply?

Terraform

↓

Reads Plan

↓

Creates Dependency Graph

↓

Creates VPC

↓

Creates Subnet

↓

Creates Security Group

↓

Creates Key Pair

↓

Creates EC2

↓

Updates State

↓

Uploads State to S3

↓

Releases Lock

---

# Why did we create modules?

Without modules

Every project

Copy

Paste

Copy

Paste

Copy

Paste

Huge maintenance effort.

With modules

Single source of truth.

One fix.

Every environment gets updated.

---

# Why did we separate environments?

Development

Testing

Production

All have different

Resources

Tags

CIDR

Variables

State

Destroying Dev should never destroy Production.

---

# Best Practices

✔ Keep backend separate.

✔ Create reusable modules.

✔ Never hardcode values.

✔ Store variables separately.

✔ Store outputs separately.

✔ Keep documentation updated.

✔ Follow one module one responsibility.

✔ Use descriptive names.

✔ Tag every AWS resource.

✔ Keep state remote.

---

# Common Mistakes

Keeping everything in one main.tf

Hardcoding AMI IDs

Hardcoding VPC IDs

Duplicating code

Using local backend

Not using modules

Editing terraform.tfstate manually

Mixing backend and infrastructure

---

# Real Production Architecture

GitHub

↓

Developer

↓

Terraform Cloud / Jenkins / GitHub Actions

↓

Terraform

↓

Remote Backend

↓

AWS Provider

↓

AWS Resources

Infrastructure is never created manually.

Everything goes through CI/CD.

---

# What We Built

Backend

↓

S3

↓

DynamoDB

↓

Remote State

↓

Workspace

↓

Modules

↓

VPC

↓

Subnet

↓

Security Group

↓

Key Pair

↓

EC2

↓

Outputs

---

# Interview Questions

## Q1. Why did you create separate modules?

### Answer

Modules improve code reusability, maintainability, and readability. Instead of rewriting the same Terraform resources for every environment, we encapsulated related resources such as EC2, VPC, and Security Groups into reusable modules. This follows the DRY (Don't Repeat Yourself) principle.

---

## Q2. Why is the backend kept in a separate folder?

### Answer

Terraform needs the backend before it can store the state. If the backend resources (S3 and DynamoDB) were in the same project that uses the backend, Terraform would have a circular dependency. Therefore, the backend is created once using a separate Terraform project.

---

## Q3. Why didn't you create all resources inside main.tf?

### Answer

A single `main.tf` becomes difficult to maintain as the project grows. Splitting resources into modules improves organization, makes debugging easier, allows multiple engineers to work independently, and supports code reuse across environments.

---

## Q4. What is the purpose of the backend-config folder?

### Answer

The backend-config folder stores environment-specific backend settings, such as the S3 bucket, state file key, region, and DynamoDB table. This allows the same Terraform code to be reused across dev, stage, and prod without modifying the configuration.

---

## Q5. Why do we separate variables, outputs, locals, and data sources into different files?

### Answer

Separating configuration by responsibility improves readability and maintainability. Variables define inputs, outputs expose useful values, locals simplify repeated expressions, and data sources fetch existing infrastructure. This makes the project easier to understand and update.

---

## Q6. Why are modules considered best practice?

### Answer

Modules make infrastructure reusable, reduce duplication, improve consistency, simplify testing, and allow teams to build standardized infrastructure components that can be shared across multiple projects.

---

## Q7. Explain your project's folder structure.

### Answer

My project consists of a dedicated backend folder for S3 and DynamoDB, an infrastructure folder containing the root Terraform configuration, reusable modules for each infrastructure component, backend configuration files for each environment, and documentation that explains the architecture, deployment process, troubleshooting, and interview concepts.