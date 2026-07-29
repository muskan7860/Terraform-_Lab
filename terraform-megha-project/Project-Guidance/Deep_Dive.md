# EXPLANATION.md — How This Project Was Built, Block by Block

This document walks through **every stage** of building `terraform-megha-project`, in the order it was actually built — including the real errors hit along the way, why they happened, and how they were fixed. It's written so that someone with **zero prior Terraform experience** can read it top to bottom and understand not just *what* was typed, but *why*.

---

## Lesson 1 — Why a Remote Backend Instead of Local State?

**Real-world analogy:** Imagine a shared Google Doc vs. a Word file saved only on your laptop. If Terraform's state file (`terraform.tfstate`) lives only on your laptop, no one else — and no CI/CD pipeline — can safely run `terraform apply` without risking two people overwriting each other's changes, or the state file simply being lost if the laptop dies.

**What we built:** Two small modules that exist purely to support Terraform itself:

- **`modules/s3`** — creates an S3 bucket to store `terraform.tfstate` remotely, with:
  - **Versioning** enabled, so previous state files aren't lost if something goes wrong
  - **Server-side encryption**, so the state file (which can contain sensitive values) isn't stored in plaintext
  - **Public access block**, so the bucket is never accidentally exposed to the internet
- **`modules/dynamodb`** — creates a DynamoDB table used purely for **state locking**. Before any `apply`, Terraform writes a lock record here. If someone else tries to `apply` at the same time, Terraform blocks them until the lock is released. This prevents two simultaneous applies from corrupting the state.

**The confusion we cleared up:** local state vs. remote state isn't an either/or forever — it's a **bootstrapping problem**. On the very first run, Terraform doesn't have a remote backend to talk to yet (the bucket and table don't exist!), so the *first* `apply` effectively runs against local state to **create** the S3 bucket and DynamoDB table. Once those exist, `backend.tf` is configured to point at them, `terraform init` migrates the state into S3, and every apply after that is remote, locked, and shared.

**Why this shows up as a real prompt:** the backend block asks for a bucket name and a table name because Terraform needs to know *where* to store/lock state before it does anything else — this is configured in `infra-app/backend.tf`.

---

## Lesson 2 — Terraform Workspaces (dev / stage / prod)

**Real-world analogy:** Same house blueprint, three different plots of land. The blueprint (code) doesn't change — only which plot (environment) it's being built on.

**What we built:** The same module code is reused across three isolated environments using:

```bash
terraform workspace new dev
terraform workspace select dev
terraform workspace show     # confirms which workspace is active
```

Each workspace gets its **own state file**, so resources created in `dev` are completely invisible to `stage` or `prod` — even though the exact same `.tf` files are being applied. Instance sizing and count are driven off `terraform.workspace` inside `variables.tf`/`main.tf`, so `prod` can safely be configured to use larger/more instances than `dev` without duplicating any code.

---

## Lesson 3 — Modular Architecture

**Real-world analogy:** Instead of one giant electrical panel wiring an entire building by hand, an electrician uses standardized, labeled circuit modules — one for lighting, one for HVAC, one for outlets — each with clearly defined inputs and outputs.

**What we built:** Every AWS resource type lives in its own module under `modules/`, each with the same three files:

- `main.tf` — the actual resource block(s)
- `variables.tf` — what the module needs from the caller
- `outputs.tf` — what the module exposes back to the caller

The root module (`infra-app/main.tf`) then wires these together:

```hcl
module "vpc" {
  source = "../modules/vpc"
  # inputs...
}

module "ec2" {
  source    = "../modules/ec2"
  subnet_id = module.vpc.public_subnet_ids[0]
  # ...
}
```

**Why this matters in production:** changing how a subnet is created only requires touching `modules/vpc` — every consumer of that module picks up the change automatically, instead of hunting through one massive file.

---

## Lesson 4 — Dynamic AMI Lookup

**Real-world analogy:** Instead of writing down today's newspaper date and it becoming stale tomorrow, you ask "give me today's paper" every time.

**What we built:** Rather than hardcoding an AMI ID (which is region-specific and gets deprecated by AWS over time), the EC2 module uses a `data "aws_ami"` block with filters (owner, name pattern, virtualization type) to always resolve the **latest matching AMI** at apply time. This is why the project doesn't silently break a few months later when AWS retires the AMI ID that was hardcoded on day one.

---

## Lesson 5 — Dynamic Availability Zones

**Real-world analogy:** Instead of hardcoding "use aisle 3 and aisle 5" in every store regardless of layout, you ask each store "which aisles do you have?" and use whatever comes back.

**What we built:** A `data "aws_availability_zones" "available"` block fetches the AZs actually available in the account's current region, instead of hardcoding `us-east-1a`, `us-east-1b`. This makes the same code portable across regions and resilient to AWS retiring or adding AZs.

---

## Lesson 6 — Multi-AZ Subnets with `count`, and the Splat Expression Error

This is where the project hit its first real, instructive error — and it's one of the most common "aha" moments when learning Terraform.

**Before:** the VPC module had a single public subnet:

```hcl
resource "aws_subnet" "public" {
  # single subnet, no count
}
```

**Change made:** to support Multi-AZ, `count` was introduced, driven by a list of CIDR blocks:

```hcl
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  # ...
}
```

**What broke, and why:** the moment `count` is added, `aws_subnet.public` stops being a single resource and becomes a **list of resource instances**: `aws_subnet.public[0]`, `aws_subnet.public[1]`. Any code still referencing `aws_subnet.public.id` (singular) fails, because Terraform no longer knows *which* instance's ID you mean.

```
Error: Unsupported attribute
  module.vpc is object with 3 attributes
  This object does not have an attribute named "public_subnet_id".
```

**The fix — splat expressions:**

```hcl
# modules/vpc/outputs.tf
output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = aws_subnet.public[*].id
}
```

`[*]` is a **splat expression**: it extracts the same attribute (`.id`) from *every* instance created by `count` (or `for_each`) and returns them as a list, instead of erroring out asking "which one?"

**Why the error kept reappearing after one fix:** renaming a module's output is a **breaking interface change** — every file consuming the old name has to be updated too, not just the module itself. The chain of files that needed the rename:

1. `modules/vpc/outputs.tf` → `public_subnet_id` became `public_subnet_ids` (list)
2. `infra-app/outputs.tf` → had to reference `module.vpc.public_subnet_ids` instead of the old singular name
3. `infra-app/main.tf` → the EC2 module call had to change `subnet_id = module.vpc.public_subnet_id` to `subnet_id = module.vpc.public_subnet_ids[0]`, since the EC2 module (at this stage) still only creates one instance and only needs one subnet

**How to catch every remaining reference safely:**

```bash
grep -R "public_subnet_id" .
```

This searches the entire project for every remaining use of the *old* singular name, so nothing is missed. This is exactly how a module's interface change is safely rolled out in a real codebase — grep for the old symbol, confirm every call site is updated, then validate.

**Verification loop used throughout:**

```bash
terraform fmt -recursive   # auto-formats all .tf files consistently
terraform validate         # checks syntax + internal consistency, no AWS calls made
terraform plan             # shows exactly what would change, against real AWS state
```

---

## Lesson 7 — The EC2 "Couldn't Find Resource" Error

```
Error: collecting instance settings: couldn't find resource
  with module.ec2.aws_instance.ec2[0]
```

This surfaced during `terraform apply`, after the VPC, S3, and DynamoDB resources had already been created successfully. It's a classic **dependency-timing / invalid-input** error at the EC2 layer — it means the `aws_instance` resource was given a value (commonly the AMI ID, or a subnet/AZ combination) that AWS couldn't resolve into an actual instance at creation time. Tracing it back to its root cause (rather than just retrying) is what led directly into Lesson 6 above — auditing every input EC2 depends on (subnet ID, AMI ID, key pair name) and confirming each one was still valid after the subnet output type changed from a single ID to a list.

**Troubleshooting approach used:**
1. Read the error location precisely — `modules/ec2/main.tf` line 3, the `aws_instance` resource block itself
2. Checked every variable being passed into that resource from the root module
3. Cross-checked against the most recent module interface changes (the subnet output rename above)
4. Re-ran `terraform validate` before touching AWS again, to catch reference errors for free without waiting on a slow `apply`

---

## Lesson 8 — Key Pair for EC2 SSH Access

**Real-world analogy:** A physical front-door key vs. a copy of that key. AWS needs to know the **public** key so it can install it on the instance; the **private** key stays only on the operator's machine and is never uploaded anywhere.

**What we built:** `modules/keypair` creates an `aws_key_pair` resource from an **existing local public key** (referenced from the local SSH keys folder), rather than having Terraform generate a brand-new key pair. This mirrors the real production pattern: the private key an engineer already has and trusts is what should be used to SSH in — Terraform's job is only to register the corresponding public key with AWS, not to mint new key material that then has to be redistributed securely.

---

## Lesson 9 — Security Groups

**Real-world analogy:** A building's front-desk access list — who's allowed in, through which door, and where they're allowed to go once inside.

**What we built:** `modules/security_group` defines an `aws_security_group` that scopes inbound access (e.g. SSH on port 22, restricted to the operator's IP rather than `0.0.0.0/0`) and allows the outbound traffic the instance needs. This is attached to the EC2 instance via its `vpc_security_group_ids`.

---

## Lesson 10 — The Free-Tier Cost Decision (Why No Load Balancer, Yet)

At this point the core stack (VPC, Multi-AZ subnets, IGW, route table, EC2, security group, key pair, remote backend, workspaces) was fully working. The next natural step in a production build is usually an **Application Load Balancer (ALB)** in front of the EC2 instance(s).

**The decision made, and why:** an ALB was deliberately **not** added in this phase, because:
- ALBs are not reliably covered by AWS Free Tier
- They run continuously (24×7) and bill for running hours + LCUs + data processed, regardless of whether there's real traffic
- For a personal lab account, the risk of an unexpected bill outweighs the learning value at this stage

This is itself a real, defensible **senior-level engineering decision**: not every "next logical step" belongs in every phase — scope was intentionally split so the free-tier-safe foundation (Phase 1) is complete and stable, and ALB / Auto Scaling Group / NAT Gateway / private subnets / Route53 / ACM / WAF are deferred to a later phase on a sandbox or paid account, once CI/CD (Phase 2) is in place to manage that added complexity safely.

---

## Lesson 11 — What's Next

With Phase 1 (this project) pushed to GitHub and tagged as complete, the next phase wires this same Terraform codebase into a **Jenkins CI/CD pipeline**:

```
GitHub → Jenkins → terraform init → terraform validate → terraform plan
       → Manual Approval → terraform apply
```

This mirrors how most real infrastructure teams begin automating Terraform: code is version-controlled first, proven to work manually, and only then wrapped in a pipeline with the same commands a human was already running by hand.

---

# Part 2 — Jenkins CI/CD Phase

## Lesson 12 — Why Split `backend/` from `infra-app/`?

**Real-world analogy:** you can't build the foundation of a house using a blueprint that's stored inside the house itself. The storage location has to exist independently, before anything else can reference it.

**What we built:** the remote backend (S3 bucket + DynamoDB table) was pulled into its own root module, `backend/`, applied first and on its own. `infra-app/` then references that backend via `-backend-config=../backend/<env>.hcl` — a separate `.hcl` file per environment (`dev.hcl`, `stage.hcl`, `prod.hcl`) holding just the bucket key/region/table for that environment's state. This mirrors Lesson 1 (local-vs-remote bootstrapping) but formalizes it into two permanent, separately-applied root modules instead of a one-time manual step.

**Why per-environment `.hcl` files instead of one shared config:** each environment's state has to live at its own key in the S3 bucket (or its own bucket entirely) — otherwise `dev` and `prod` would silently share one state file and one workspace would overwrite the other's infrastructure.

---

## Lesson 13 — Jenkins Credentials: Why the GitHub Token Didn't Show Up

**Symptom:** a GitHub token was added as a Jenkins credential, but only the DockerHub credential appeared in the pipeline's credential dropdown.

**Root cause:** Jenkins credentials are typed. A GitHub Personal Access Token has to be stored as **"Secret text"** (or "Username with password", using the token as the password) — not as some other credential kind — and it has to be scoped/visible to the correct Jenkins folder or global scope the pipeline is running under. If the pipeline's `Checkout` stage or `withCredentials()` block references a credential ID that doesn't match what was actually created, Jenkins simply won't offer it.

**The fix pattern:** create the token explicitly as **Secret text**, give it a clear credential ID (e.g. `github-creds`), and reference that exact ID in the Jenkinsfile's `checkout` step or `credentialsId` field — then it appears correctly, as seen once `Checkout SCM` began successfully authenticating with `using credential github-creds`.

---

## Lesson 14 — AWS Credentials on the Agent, Not the Controller

**Real-world analogy:** giving your assistant a set of keys doesn't help if the person actually opening the door is someone else entirely.

**The error:** Terraform reported `No valid credential sources found` even though AWS credentials had already been added in Jenkins.

**Root cause:** the pipeline's log clearly showed `Running on terraform-agent` — meaning the actual Terraform commands execute inside a **separate Jenkins agent pod**, not the Jenkins controller pod. The AWS credentials had been added to the **controller** Deployment's environment, which the agent never sees.

**Diagnosis:**
```bash
kubectl exec -it deployment/jenkins-agent -n monitoring -- env | grep AWS
# (no output — confirms the agent has no AWS env vars)
```

**The fix — patch the agent Deployment, not the controller:**
```bash
kubectl patch deployment jenkins-agent -n monitoring --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/env",
    "value": [
      { "name": "AWS_ACCESS_KEY_ID",     "valueFrom": { "secretKeyRef": { "name": "aws-credentials", "key": "AWS_ACCESS_KEY_ID" } } },
      { "name": "AWS_SECRET_ACCESS_KEY", "valueFrom": { "secretKeyRef": { "name": "aws-credentials", "key": "AWS_SECRET_ACCESS_KEY" } } },
      { "name": "AWS_DEFAULT_REGION",    "valueFrom": { "secretKeyRef": { "name": "aws-credentials", "key": "AWS_DEFAULT_REGION" } } }
    ]
  }
]'
kubectl rollout status deployment/jenkins-agent -n monitoring
kubectl exec -it deployment/jenkins-agent -n monitoring -- env | grep AWS   # now shows the values
```

**Why the exact patch mattered:** the first patch attempt used `path: "/spec/template/spec/containers/0/env/-"` (append to an existing array) three separate times, but the agent container (`jnlp`) had **no `env:` key at all** yet — you can't append to an array that doesn't exist. Once confirmed via `kubectl get deployment jenkins-agent -o yaml`, the patch was corrected to `path: "/spec/template/spec/containers/0/env"` (create the array directly, `add` not append) in a single operation.

**Broader lesson:** a JSON Patch `add` operation behaves differently depending on whether the target path already exists — check the actual current object structure before writing the patch, rather than assuming a key like `env:` is already there.

---

## Lesson 15 — DNS Inside the Cluster: Two Different Failures, One Root Cause Category

This was the most involved troubleshooting chain in the project — two separate-looking errors that both trace back to in-cluster DNS.

### 15a — "network is unreachable" reaching `registry.terraform.io`

**Symptom, during the `Create Backend` stage:**
```
Error: Failed to query available provider packages
dial tcp [2600:9000:237b:d600:...]:443: connect: network is unreachable
```

**Reading the error correctly:** the address in brackets is an **IPv6** address. The cluster's networking (or the underlying host) doesn't have working IPv6 egress, but DNS resolution returned an IPv6 (AAAA) record for `registry.terraform.io` anyway, and Terraform tried that first and had no route to reach it.

### 15b — CoreDNS returning `REFUSED` for every external domain

**Symptom, tested directly:**
```bash
kubectl exec -it -n monitoring jenkins-agent-... -- bash
curl -I https://ec2.ap-south-1.amazonaws.com
# curl: (6) Could not resolve host: ec2.ap-south-1.amazonaws.com
```

A throwaway busybox pod confirmed it wasn't specific to the Jenkins agent — **no pod in the cluster** could resolve external hostnames, even though the **host machine's** own DNS worked fine.

**Root cause:** the CoreDNS `Corefile` (its ConfigMap) had:
```
forward . /etc/resolv.conf
```
Inside the CoreDNS **container itself**, `/etc/resolv.conf` is not the host's resolver — it's the pod's own resolver, which Kubernetes points back at the cluster's internal DNS service. That created an invalid forwarding path (effectively CoreDNS asking itself), which the upstream resolver correctly refused rather than looping forever — hence `REFUSED` instead of a timeout.

**The fix — forward to real upstream DNS explicitly:**
```bash
microk8s kubectl patch configmap coredns -n kube-system \
  --type merge \
  -p '{"data":{"Corefile":".:53 {\n    errors\n    health { lameduck 5s }\n    ready\n    log . { class error }\n    kubernetes cluster.local in-addr.arpa ip6.arpa {\n      pods insecure\n      fallthrough in-addr.arpa ip6.arpa\n    }\n    prometheus :9153\n    forward . 103.14.232.100 8.8.8.8\n    cache 30\n    loop\n    reload\n    loadbalance\n}\n"}}'

microk8s kubectl rollout restart deployment/coredns -n kube-system
microk8s kubectl rollout status deployment/coredns -n kube-system
```
`103.14.232.100` is the host network's own working resolver, and `8.8.8.8` (Google DNS) is a reliable fallback — both are real upstream servers a pod can actually reach, unlike `/etc/resolv.conf` which was chasing its own tail inside the CoreDNS pod.

**Verification method used — never trust a single symptom:**
```bash
microk8s kubectl run dns-test --rm -it --image=busybox:1.36 --restart=Never -- sh
# then inside the pod:
nslookup google.com
nslookup ec2.ap-south-1.amazonaws.com
nslookup terraform-megha-project-tfstate.s3.ap-south-1.amazonaws.com
```
A disposable test pod isolates the problem from any pipeline-specific noise — if a plain busybox pod can't resolve DNS, the issue is cluster-wide, not Jenkins-specific.

**Housekeeping lesson learned from the same investigation:** the cluster had been running 96 days with elevated restart counts on CoreDNS, Calico, and the hostpath-provisioner — a reminder that long-lived single-node lab clusters benefit from periodic `microk8s stop && microk8s start` maintenance, since accumulated restarts can mask or contribute to intermittent networking issues.

---

## Lesson 16 — Debugging a Pipeline Without Leaving the Workspace Behind

**The problem:** the Jenkinsfile's `always { ... deleteDir() }` post-action wipes the entire workspace after every build — success or failure — which meant that manually `exec`-ing into the agent afterward to inspect files (like `.terraform.lock.hcl`) found nothing, because the workspace was already gone.

**The fix, temporarily:**
```groovy
always {
    archiveArtifacts artifacts: '**/tfplan', allowEmptyArchive: true
    // deleteDir()
}
```
Comment out (don't delete) the cleanup step, commit, push, and re-run the pipeline. On failure, the workspace now survives long enough to `exec` in and inspect it directly:
```bash
cd /home/jenkins/agent/workspace/terraform-pipeline
find . -name ".terraform.lock.hcl"
```

**Why this matters as a practice, not just a one-off fix:** this is the standard way engineers debug CI agents in production — temporarily disable cleanup, investigate with the real artifacts in place, then **re-enable cleanup once resolved** so builds don't silently accumulate disk usage on the agent long-term.

---

## Lesson 17 — Diagnosing Provider Plugin Caching

**What was configured:** `~/.terraformrc` pointing at a `plugin_cache_dir`, backed by `~/.terraform.d/plugin-cache`, intended to avoid re-downloading the same AWS provider version on every single pipeline run.

**How to tell if the cache is actually being used:** Terraform's own init output says it directly —
```
Using hashicorp/aws v6.56.0 from the shared cache directory
```
vs. the cache **not** being used:
```
Installing hashicorp/aws v6.56.0...
```
The pipeline was still showing `Installing` during the `Create Backend` stage, meaning the cache wasn't taking effect yet.

**Systematic diagnosis added to the pipeline** (temporary debug block in the `Verify Tools` stage):
```bash
echo "HOME=$HOME"
echo "USER=$(whoami)"
ls -la $HOME
ls -la $HOME/.terraform.d
cat $HOME/.terraformrc
```
This isolates the possible causes down to one of: the cache directory not actually being persistent storage (e.g. not backed by a PVC, so it resets on every new agent pod), `.terraformrc` not present under the `HOME` Terraform actually sees at runtime, or Terraform running under a different effective `HOME` than expected.

---

## Lesson 18 — The "Lock" Failure That Wasn't a Lock Failure

**Symptom:** a pipeline run failed with `ERROR: script returned exit code 255` right after the backend stage, and it was initially assumed to be a Terraform **state lock contention** error (`Error acquiring the state lock`), because DynamoDB was involved.

**Reading the log precisely — the actual failure point:**
```
+ aws s3api head-bucket --bucket terraform-megha-project-tfstate
+ S3_EXISTS=0
+ aws dynamodb describe-table --table-name terraform-megha-project-locks
[Pipeline] // stage
Stage "Terraform Init" skipped due to earlier failure(s)
```
Notice: **no output at all** after the `aws dynamodb describe-table` line, and the very next stages are skipped. That means the shell command itself exited non-zero — Terraform never even reached `terraform init`, so this could not have been a Terraform state-lock error; Terraform's locking logic hadn't run yet.

**Why the "lock" assumption was reasonable but wrong:** the backend config does use a `dynamodb_table` named `...-locks`, so any DynamoDB-adjacent failure naturally gets read as a locking problem — but the actual command that failed is a plain **pre-flight existence check** the pipeline runs before Terraform touches anything, to decide whether the backend resources need to be created for the first time.

**Correct triage checklist for this exact failure shape (a bare AWS CLI command failing silently under `set -e`):**
```bash
# 1. Does the table actually exist / is the name right?
aws dynamodb describe-table --table-name terraform-megha-project-locks --region ap-south-1

# 2. Are the credentials even valid from this pod?
aws sts get-caller-identity

# 3. Is the region correct in this shell?
aws configure list
echo $AWS_REGION
echo $AWS_DEFAULT_REGION

# 4. Does the IAM identity have the needed DynamoDB permissions?
#    dynamodb:DescribeTable, GetItem, PutItem, DeleteItem
```

**General lesson:** when a CI script fails between two AWS CLI calls with zero output and a bare non-zero exit code, resist the pull toward whatever resource name is most visually similar to a familiar error ("lock" → state locking) and instead trace the **exact line the log stopped at** — the fastest way to find the real cause is reproducing that one command in isolation, not re-running the whole pipeline and hoping.

---

## Lesson 19 — Environment- and Action-Parameterized Pipeline

**What we built:** the same Jenkinsfile drives `dev`, `stage`, and `prod`, and both `apply` and `destroy`, via build parameters — visible directly in the Slack failure notifications:
```
❌ Terraform apply FAILED
Environment : prod
Job         : terraform-pipeline
Build       : #54
```
```
❌ Terraform destroy FAILED
Environment : prod
Job         : terraform-pipeline
Build       : #55
```

**Why this is the production pattern:** rather than maintaining three near-duplicate Jenkinsfiles (or three separate jobs) for dev/stage/prod, one parameterized pipeline keeps the promotion logic (and every fix made to it) identical across environments — a bug fixed once in the Jenkinsfile is fixed everywhere, and the actual difference between environments lives only in the `.hcl` backend config and the `.tfvars`/workspace values, exactly where environment-specific differences belong.