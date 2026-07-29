# INTERVIEW_QA.md — Questions & Answers Based on This Project

These are interview questions mapped directly to real decisions and real errors made while building `terraform-megha-project`. Answers are written in a spoken, explain-it-to-the-interviewer style — lead with the concept, then ground it in what was actually built.

---

## Section 1 — Remote State & Backend

**Q1. Why did you use an S3 backend instead of local state?**
Local state works fine solo, but it doesn't scale to a team or a pipeline — there's no locking, no shared source of truth, and if the laptop is lost, the state is gone. I moved state into an S3 bucket so it's centrally stored, versioned, and encrypted, and paired it with a DynamoDB table purely for state locking, so two people or two pipeline runs can never `apply` against the same state at the same time.

**Q2. How does Terraform actually use DynamoDB for locking?**
Before any operation that can modify state, Terraform writes a lock item to the configured DynamoDB table. If another process tries to run `apply` while that lock exists, Terraform blocks it with a "state locked" error until the first operation finishes and releases the lock. It's a safety mechanism, not a resource being provisioned for the application itself.

**Q3. If the backend resources (S3 bucket, DynamoDB table) don't exist yet, how do you create them with Terraform if Terraform itself needs a backend to run?**
That's a genuine bootstrapping problem. The first apply runs with local state to create the S3 bucket and DynamoDB table. Once they exist, the backend configuration is added/updated to point at them, and `terraform init` migrates the existing local state into S3. From that point forward, every operation is remote and locked.

**Q4. What security measures did you put on the state bucket, and why?**
Versioning, so a bad state write can be rolled back; server-side encryption, because state files can contain sensitive attribute values; and a public access block, so the bucket can never be accidentally exposed — state files are effectively a blueprint of the infrastructure and should never be public.

---

## Section 2 — Workspaces

**Q5. What are Terraform workspaces, and why did you use them here instead of separate directories per environment?**
Workspaces let the same codebase be applied against multiple isolated state files — one per environment — without duplicating `.tf` code. I used `dev`, `stage`, and `prod` workspaces so the exact same modules can size resources differently per environment (via `terraform.workspace` in the variables), while keeping each environment's actual infrastructure and state completely separate.

**Q6. What's a real limitation of workspaces that you'd flag to a team considering them for prod?**
Workspaces isolate *state*, not code or variables by default — if you're not careful, a variable meant only for `dev` can accidentally apply to `prod` because the underlying `.tf` files are identical across workspaces. For stricter separation (e.g. different AWS accounts per environment), many teams move to separate root modules or separate backend configs per environment instead of relying purely on workspaces.

---

## Section 3 — Modules

**Q7. Why split this into modules instead of one main.tf?**
Each AWS resource type — VPC, EC2, security group, key pair, S3, DynamoDB — has its own lifecycle and its own reasonable set of inputs/outputs. Splitting them into modules means each one is independently testable, reusable across environments, and a change to how subnets are created only touches the VPC module rather than a 500-line flat file.

**Q8. What's the difference between a module's input variables and its outputs, and why does that matter?**
`variables.tf` defines what the module *needs* from whoever calls it — its contract inbound. `outputs.tf` defines what it *exposes* back — its contract outbound. Together they form the module's interface. That distinction matters because when I later changed an output's name and type (see the subnet question below), I had to think of it as changing a public interface, not just editing a file.

---

## Section 4 — Networking (VPC / Subnets / Multi-AZ)

**Q9. Walk me through how you made your subnets Multi-AZ.**
Originally the VPC module created a single public subnet. I introduced a `count = length(var.public_subnet_cidrs)` on the subnet resource, driven by a variable holding a list of CIDR blocks, so the number of subnets created scales with however many CIDRs are provided — one per Availability Zone.

**Q10. What broke when you added `count` to the subnet resource, and why?**
The moment `count` is added, `aws_subnet.public` is no longer a single resource — it becomes a list of instances (`aws_subnet.public[0]`, `[1]`, etc). Any output still written as `aws_subnet.public.id` fails, because Terraform has no way to know which instance's ID is meant. The error was literally: the module object "does not have an attribute named public_subnet_id" — because I'd renamed the output but hadn't yet updated every file consuming the old name.

**Q11. What's a splat expression, and how did you use it here?**
`[*]` is a splat expression — it pulls the same attribute off every instance created by `count` or `for_each` and returns them as a list. I used `aws_subnet.public[*].id` to turn "the ID of subnet 0 or 1, whichever you meant" into a clean list of all subnet IDs, which the output then exposes as `public_subnet_ids`.

**Q12. Once you renamed an output from singular to plural, what else did you have to change, and how did you make sure you caught everything?**
Renaming a module output is a breaking interface change — every consumer has to update. I updated the module's own `outputs.tf`, then the root `infra-app/outputs.tf` that re-exports it, then the EC2 module call in `infra-app/main.tf`, which switched from `module.vpc.public_subnet_id` to `module.vpc.public_subnet_ids[0]` since EC2 still only needed one subnet at that stage. To make sure nothing was missed, I ran `grep -R "public_subnet_id" .` across the whole project to find every remaining reference to the old name before re-running `terraform validate`.

**Q13. Why did EC2 use `public_subnet_ids[0]` instead of the full list?**
Because at that point the project only provisioned a single EC2 instance — it needs exactly one subnet to live in. The list of all AZ subnets exists for future use (an Auto Scaling Group or Load Balancer spanning multiple AZs), but until those exist, indexing `[0]` is the correct, honest choice rather than pretending the EC2 module needs more than it does.

**Q14. Why dynamic AZs and dynamic AMI lookups instead of hardcoding them?**
Hardcoded AZ names and AMI IDs are region-specific and go stale — AWS deprecates AMIs and regions don't share AZ names. Using a `data "aws_availability_zones"` source and a `data "aws_ami"` source with filters means the same code is portable across regions and doesn't silently break months later when an AMI is retired.

---

## Section 5 — Compute & Access

**Q15. How did you handle SSH access to the EC2 instance?**
Through an `aws_key_pair` resource that registers an **existing** local public key with AWS, rather than having Terraform generate new key material. The private key stays local and was never something Terraform needed to create or manage — Terraform's only job is telling AWS which public key is authorized.

**Q16. You hit an error: "collecting instance settings: couldn't find resource" on the EC2 resource. Walk me through how you debugged it.**
I started at the exact location in the error — the `aws_instance` resource block in the EC2 module — and worked backward through every value it depended on: the AMI ID coming from the dynamic AMI data source, and the subnet ID being passed in from the VPC module. That traced directly back to the subnet output rename that was in progress at the same time — the EC2 module was still referencing the old singular subnet output, which no longer resolved correctly after `count` was introduced. Fixing the output chain (Q10–Q13) resolved it. The general lesson: read exactly where Terraform says the error occurred, then audit every input feeding that resource rather than guessing.

**Q17. Why didn't you add a Load Balancer or Auto Scaling Group in this phase?**
Deliberate scope decision, not a limitation I hit — an ALB runs continuously and bills for running hours, LCUs, and data processed regardless of traffic, and isn't reliably Free Tier eligible. For a lab/learning AWS account, I chose to keep Phase 1 to what's safely free — VPC, subnets, one EC2 instance, security group, remote backend — and defer ALB/ASG/NAT Gateway/private subnets to a later phase on a sandbox or paid account, once CI/CD is in place to manage that added complexity safely.

---

## Section 6 — General Terraform Troubleshooting

**Q18. What's your general workflow when a `terraform apply` fails partway through?**
First, don't panic-retry — re-run `terraform plan` to see current state vs. desired state; Terraform is designed to be idempotent, so a partial apply is safe to re-run once the actual cause is fixed. Second, read the exact resource address and file/line in the error. Third, run `terraform validate` to catch any syntax/reference errors for free, without waiting on a slow AWS round trip. Fourth, check whether the error is a genuine AWS-side issue (quota, invalid AMI, timing) vs. a Terraform code issue (broken reference, wrong type).

**Q19. What's the difference between `terraform validate` and `terraform plan`?**
`validate` only checks that the configuration is internally syntactically and referentially consistent — it doesn't call AWS at all. `plan` actually talks to the provider, refreshes real state, and shows exactly what would be created, changed, or destroyed. I used `validate` as a fast first check after every code change, and `plan` before every real apply.

**Q20. Why run `terraform fmt -recursive` as part of your workflow?**
It auto-formats every `.tf` file in the project tree to Terraform's canonical style — consistent indentation and alignment. It doesn't change behavior, but it keeps a multi-module project readable and diff-friendly in version control, which matters once more than one person (or a CI pipeline) is touching the code.

**Q21. How would you avoid the "renamed output breaks every consumer" problem happening silently again in a team setting?**
In practice: treat module outputs as a versioned interface — document them, and when a breaking rename is unavoidable, grep the whole repo for the old name before merging, exactly as done here. On a team, this is also where a CI step running `terraform validate` (and ideally `plan`) on every pull request earns its keep — it catches a broken reference before it ever reaches `apply`.

---

## Section 7 — CI/CD Architecture

**Q22. Why did you split `backend/` and `infra-app/` into two separate Terraform root modules instead of one?**
The backend has to exist before anything else can point Terraform at it remotely — it can't be created from within the same state it's meant to store. So `backend/` is applied on its own first to create the S3 bucket and DynamoDB table, and `infra-app/` then initializes against that backend using `-backend-config` per environment. It also mirrors real practice: backend infrastructure changes far less often than application infrastructure, so keeping them as separate lifecycles avoids accidentally touching state-storage resources during a routine app-infra change.

**Q23. Why one Jenkinsfile for dev/stage/prod instead of three separate pipelines?**
A single pipeline parameterized by environment and action (apply/destroy) means any fix or improvement to the pipeline logic applies everywhere at once, instead of drifting across three near-duplicate files. The actual per-environment differences are isolated to the backend `.hcl` files and workspace-driven variables — exactly where environment-specific config belongs, not duplicated into the pipeline logic itself.

**Q24. Walk me through your pipeline stages and what each one is responsible for.**
Checkout pulls the repo using a scoped GitHub credential; Verify Tools confirms the Terraform/AWS CLI/git versions available on the agent and runs a DNS sanity check; Create Backend bootstraps the S3/DynamoDB backend if it doesn't exist yet; Terraform Init and Workspace point the app-infra module at the right backend and environment; Validate and Plan are read-only safety checks, with the plan archived as a build artifact; Approval is a manual human gate before anything destructive runs; Apply or Destroy executes the real change; and Post Actions always run — archiving the plan and sending a Slack notification regardless of outcome.

---

## Section 8 — Jenkins Credentials & Agent Architecture

**Q25. You added a GitHub token as a Jenkins credential but it wasn't showing up when needed. What was going on?**
Jenkins credentials are typed — a GitHub token needs to be stored specifically as Secret Text (or Username/Password using the token as the password), and it needs to be referenced by the exact credential ID the pipeline expects. If it's created as the wrong type, or the ID in the Jenkinsfile doesn't match, Jenkins simply won't surface it as a usable option in that context.

**Q26. You hit "No valid credential sources found" for AWS even after adding AWS credentials in Jenkins. What was the actual issue?**
The credentials had been added to the Jenkins controller, but the pipeline log clearly showed the build running on a separate agent pod (`Running on terraform-agent`) — Terraform executes there, not on the controller, so the controller's environment is irrelevant to it. The fix was patching the same AWS credentials Secret into the Jenkins agent Deployment's own environment instead.

**Q27. How do you verify a Kubernetes Deployment's pod actually has the environment variables you think it does?**
`kubectl exec` into a running pod from that deployment and check directly — e.g. `kubectl exec -it deployment/jenkins-agent -n <namespace> -- env | grep AWS`. That's more reliable than reading the manifest, since it confirms what the running container actually sees at runtime, not just what was intended.

**Q28. Your first `kubectl patch` attempt on the agent deployment failed. Why, and what did you change?**
The patch used `path: ".../env/-"`, which appends to an existing array — but the container had no `env:` key at all yet, so there was nothing to append to. Once I confirmed the actual container spec with `kubectl get deployment ... -o yaml`, I switched to `path: ".../env"` with `op: add` and the full array as the value, creating the key directly instead of assuming it already existed.

---

## Section 9 — DNS Troubleshooting

**Q29. You saw `dial tcp [ipv6-address]:443: connect: network is unreachable` trying to reach the Terraform registry. How did you interpret that error?**
The address in brackets was IPv6 — DNS resolved an AAAA record for the registry, but the cluster/host didn't have working IPv6 egress, so the connection attempt had no route. That told me the issue was network-path related, not credentials or Terraform configuration.

**Q30. Later you found CoreDNS returning REFUSED for every external domain, even from a plain busybox pod. How did you isolate that it was cluster-wide and not specific to Jenkins?**
I ran a disposable test pod (`busybox`) unrelated to Jenkins and tried `nslookup` against a known-good domain from inside it. When even that failed the same way, it ruled out anything Jenkins-specific and confirmed the problem was at the cluster's DNS layer itself — CoreDNS.

**Q31. What was actually wrong with the CoreDNS configuration?**
The Corefile had `forward . /etc/resolv.conf`. Inside the CoreDNS container, that file isn't the host's real resolver — it's the pod's own resolver config, which points back at the cluster's internal DNS service. That created an invalid forwarding loop back to itself, which the DNS layer correctly refused rather than hanging — hence REFUSED responses instead of timeouts.

**Q32. How did you fix it, and why choose those specific upstream servers?**
I patched the CoreDNS ConfigMap to forward explicitly to two real, reachable upstream resolvers instead of the ambiguous `/etc/resolv.conf` — the host network's own working resolver, plus Google's public DNS (8.8.8.8) as a fallback — then restarted the CoreDNS deployment and re-verified with the same busybox test pod.

**Q33. Why test with `nslookup` from a temporary pod instead of just re-running the Jenkins pipeline after the fix?**
A full pipeline run is slow and has many stages that could mask or confound the result. A throwaway pod running `nslookup` against the exact hostnames the pipeline needs (`registry.terraform.io`, the AWS endpoints, the S3 bucket's own DNS name) gives a fast, isolated yes/no on whether the actual root cause is fixed, before spending time on a full pipeline re-run.

---

## Section 10 — General CI/CD Debugging Discipline

**Q34. Your Jenkinsfile has a `deleteDir()` in the `always` block that wipes the workspace after every run. How did that get in the way of debugging, and what did you do about it?**
It meant that after a failed build, exec-ing into the agent to inspect files like `.terraform.lock.hcl` found nothing, because the workspace was already deleted. I temporarily commented out just that line, re-ran the pipeline, and on failure the workspace persisted long enough to inspect directly — then re-enabled cleanup once the actual issue was found and fixed, so builds don't leave debug artifacts sitting around indefinitely.

**Q35. A pipeline failed with exit code 255 right after a DynamoDB-related command, and it looked like a state lock error. Why wasn't it?**
Reading the log precisely mattered here — Terraform hadn't even reached `terraform init` yet; the failure was on a plain `aws dynamodb describe-table` pre-flight check the pipeline runs to decide whether backend resources need creating. Terraform's own state-locking logic (which produces a distinct "Error acquiring the state lock" message) never ran. The DynamoDB table name just happens to contain the word "locks," which is what made the wrong assumption tempting.

**Q36. What's your triage order when a bare AWS CLI command fails silently in a CI script with no error output?**
Reproduce the exact same command directly against the table/resource in question; confirm the identity is even valid with `aws sts get-caller-identity`; confirm the region the shell is actually using (`aws configure list` / the `AWS_REGION`/`AWS_DEFAULT_REGION` env vars); and check whether the IAM identity actually has the specific permissions the command needs. That ordered checklist finds the real cause faster than re-running the whole pipeline speculatively.

**Q37. How do you verify Terraform provider plugin caching is actually working, versus just configured?**
Terraform's own `init` output tells you directly — `Using <provider> from the shared cache directory` means the cache hit, `Installing <provider>...` means it didn't. When it wasn't hitting, I added a debug block printing `$HOME`, the contents of `.terraform.d`, and the `.terraformrc` file itself at the exact point in the pipeline where `init` runs, to confirm whether the cache directory was even present and persistent for that specific agent pod at runtime.