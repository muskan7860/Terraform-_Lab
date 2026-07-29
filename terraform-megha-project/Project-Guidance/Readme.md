# terraform-megha-project

Production-style AWS infrastructure provisioned with modular Terraform, promoted through isolated environments (dev / stage / prod) via Terraform Workspaces, and automated end-to-end through a Jenkins CI/CD pipeline running on a self-hosted MicroK8s cluster.

This repo is built as a hands-on lab to practice the full loop a real infra team runs: write modular IaC → store state remotely and locked → validate/plan/apply by hand → then wrap the exact same commands in a CI/CD pipeline with manual approval gates, notifications, and environment parameters.

---

## 🏗️ Architecture

```
GitHub (source of truth)
   │
   ▼
Jenkins (running as a Deployment on MicroK8s, in the "monitoring" namespace)
   │  pipeline executes on a dedicated Jenkins agent pod ("terraform-agent" / jnlp),
   │  NOT on the Jenkins controller
   ▼
Jenkinsfile pipeline:
   Checkout → Verify Tools → Create Backend → Terraform Init → Workspace
   → Validate → Terraform Plan → Manual Approval → Terraform Apply / Destroy
   → Post Actions (archive plan, Slack notification)
   │
   ▼
AWS (ap-south-1)
   ┌─────────────────────────────────────────────┐
   │  Remote backend (bootstrap layer)             │
   │   S3 bucket    : terraform-megha-project-tfstate
   │   DynamoDB     : terraform-megha-project-locks
   ├─────────────────────────────────────────────┤
   │  Application infra (infra-app layer)          │
   │   VPC → Multi-AZ public subnets → IGW/RT      │
   │   Security Group → Key Pair → EC2              │
   └─────────────────────────────────────────────┘

Supporting cluster services:
   CoreDNS (in-cluster DNS resolution for the agent pod)
   Cloudflare Tunnel (exposes Jenkins UI at a public domain, no open inbound ports)
```

## 🧰 Tech Stack

| Layer | Tools |
|---|---|
| IaC | Terraform (modular, remote backend, workspaces) |
| Cloud | AWS — VPC, Subnets, IGW, Route Tables, EC2, Security Groups, Key Pair, S3, DynamoDB |
| CI/CD | Jenkins (Declarative Pipeline), running on Kubernetes as controller + dedicated agent pod |
| Container platform | MicroK8s (single-node Kubernetes lab cluster) |
| Source control | GitHub, with a `github-creds` credential in Jenkins |
| Networking / exposure | Cloudflare Tunnel (public domain, no open ports); in-cluster CoreDNS |
| Notifications | Slack webhook, posted on pipeline success/failure |
| Secrets | Kubernetes Secret (`aws-credentials`) injected into the Jenkins agent Deployment as env vars |

## 📁 Project Structure

```
terraform-megha-project/
├── backend/                       # Bootstraps the remote state backend itself
│   ├── main.tf                    # Calls s3 + dynamodb modules
│   ├── variables.tf
│   ├── outputs.tf
│   ├── dev.hcl                    # Per-environment backend-config files
│   ├── stage.hcl
│   ├── prod.hcl
│   └── .terraform.lock.hcl        # Committed so Jenkins doesn't re-resolve providers
│
├── infra-app/                     # Application infrastructure — VPC, EC2, etc.
│   ├── main.tf                    # Calls vpc, security_group, keypair, ec2 modules
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── backend.tf                 # Partial backend config, completed via -backend-config
│   └── .terraform.lock.hcl
│
├── modules/
│   ├── vpc/
│   ├── security_group/
│   ├── keypair/
│   ├── ec2/
│   ├── s3/
│   └── dynamodb/
│
└── Jenkins/
    └── Jenkinsfile                 # Declarative pipeline: backend → infra-app, per environment
```

Backend state is intentionally split from application infra into **two separate root modules** (`backend/` and `infra-app/`) — the backend has to exist *before* `infra-app` can point Terraform at it remotely, so it can't bootstrap itself from within the same state file it manages.

## ⚙️ Jenkins Pipeline Stages

```
1. Declarative: Checkout SCM
2. Clean Workspace           (deleteDir)
3. Checkout                  (explicit re-clone with github-creds)
4. Verify Tools              (terraform / aws / git versions + DNS debug block)
5. Create Backend            (terraform init in backend/, creates S3 + DynamoDB if absent)
6. Terraform Init            (infra-app/, using -backend-config per environment)
7. Workspace                 (selects/creates dev | stage | prod workspace)
8. Validate                  (terraform validate)
9. Terraform Plan            (saved as an artifact: tfplan)
10. Approval                 (manual gate before apply/destroy)
11. Terraform Apply / Terraform Destroy   (environment- and action-parameterized)
12. Declarative: Post Actions             (archiveArtifacts, Slack notification)
```

The pipeline is parameterized by **environment** (dev / stage / prod) and **action** (apply / destroy), so the same Jenkinsfile drives every environment and both directions of infrastructure lifecycle.

## 🔑 Prerequisites

- MicroK8s cluster with Jenkins (controller + agent) deployed, and a Kubernetes Secret named `aws-credentials` (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`) injected into the **Jenkins agent** Deployment's env — not just the controller
- Jenkins credentials configured: `github-creds` (GitHub token, as Secret Text or Username/Password), a Slack webhook credential for notifications
- AWS account with an IAM user/role permissioned for VPC, EC2, S3, and DynamoDB (including `dynamodb:DescribeTable`, `GetItem`, `PutItem`, `DeleteItem` for locking)
- Working outbound DNS resolution from inside the cluster (see `EXPLANATION.md` — this was a real blocker)

## ▶️ How to Run — Manually (before CI/CD)

```bash
# 1. Bootstrap the remote backend (creates the S3 bucket + DynamoDB table)
cd terraform-megha-project/backend
terraform init
terraform apply

# 2. Point infra-app at that remote backend, per environment
cd ../infra-app
terraform init -backend-config=../backend/dev.hcl -reconfigure -upgrade=false
terraform workspace new dev      # first time
terraform workspace select dev

terraform fmt -recursive
terraform validate
terraform plan
terraform apply

# Repeat with stage.hcl / prod.hcl + matching workspace to promote across environments
```

## ▶️ How to Run — via Jenkins

1. Push changes to the `main` branch on GitHub
2. Trigger (or let webhook trigger) the `terraform-pipeline` job in Jenkins
3. Select the **environment** (dev / stage / prod) and **action** (apply / destroy) build parameters
4. Review the `Terraform Plan` stage output, then approve at the manual `Approval` gate
5. Watch for the Slack notification confirming success or failure, with a direct link to the build

## 🚧 Known Operational Notes

- The Jenkins agent (`jnlp` container) had **no AWS credentials** by default — they were added to the Jenkins **controller** first by mistake, which does nothing, since Terraform actually executes on the **agent** pod. Fixed by patching the `aws-credentials` Secret into the `jenkins-agent` Deployment's env.
- In-cluster DNS initially failed to resolve any external hostname (AWS endpoints, `registry.terraform.io`, even `google.com`) due to a misconfigured CoreDNS `forward` directive creating an invalid loop back to the cluster's own resolver. Fixed by forwarding explicitly to real upstream DNS servers.
- Terraform provider plugin caching (`~/.terraformrc` + `~/.terraform.d/plugin-cache`) was configured but not yet confirmed to be effectively used by every pipeline run — the agent was still shown "Installing" rather than "Using ... from the shared cache" in at least one run.
- The cluster is a long-running (~96-day) single-node MicroK8s lab instance; several core `kube-system` pods (CoreDNS, Calico, hostpath-provisioner) had accumulated high restart counts, which is worth a periodic `microk8s stop && microk8s start` maintenance window.

## 🗺️ Roadmap

| Phase | Scope | Status |
|---|---|---|
| Phase 1 | Terraform foundation — remote backend, workspaces, modules, VPC, EC2, SG, dynamic AMI/AZ, Multi-AZ subnets | ✅ Complete |
| Phase 2 | Jenkins CI/CD — parameterized pipeline (init → validate → plan → manual approval → apply/destroy), Slack notifications, backend/infra-app split | 🟡 Built, actively being hardened (credentials, DNS, provider caching) |
| Phase 3 | Docker | Planned |
| Phase 4 | Kubernetes | Planned |
| Phase 5 | GitOps with ArgoCD | Planned |

## 📄 Companion Docs

- [`EXPLANATION.md`](./EXPLANATION.md) — lesson-by-lesson walkthrough of every block built, in order, including every real error hit (Terraform and Jenkins/Kubernetes/DNS) and how it was diagnosed and fixed
- [`INTERVIEW_QA.md`](./INTERVIEW_QA.md) — interview questions and spoken-style answers based directly on the decisions and troubleshooting done in this project