# Session 1 Instructor Guide: Foundations & first VM

Terraform Associate (004) course. The exam is based on Terraform 1.12, and the class pins one exact 1.12.x or later.
Session length: 3:30 (3:15 teaching, one 15-minute break). Platform: platform-free plus vSphere only. No AWS in this session.
Students are **online** and run Terraform **from their own laptops**. Lab 1.2 goes straight to an **ESXi host** (no vCenter); Lab 1.3 is a short vCenter comparison.

Related files: [`README.md`](README.md) (student timeline), [`00-precheck/precheck.sh`](00-precheck/precheck.sh), [`01-providers/`](01-providers/README.md) (Lab 1.1), [`02-first-vm/`](02-first-vm/README.md) (Lab 1.2), [`03-vcenter-vm/`](03-vcenter-vm/README.md) (Lab 1.3), [`lab-setup-guide.md`](lab-setup-guide.md), [`quiz.md`](quiz.md).

---

## 1. At a glance

### Objectives covered

| Obj | What the student can do afterwards | Where |
|---|---|---|
| 1a | Explain what IaC is and why it beats clicking | 0:15 block |
| 1b | Name the benefits: idempotency, versioning, review, reuse | 0:15 block |
| 1c | Explain multi-cloud, hybrid-cloud and service-agnostic workflows | 0:45 block |
| 2a | Install providers, set version constraints, explain the lock file | Lab 1.1 |
| 2b | Explain how Terraform uses providers (plugins, source addresses, `init`) | Lab 1.1, Lab 1.2 step 2 |
| 3a | Describe the workflow: write, init, plan, apply, destroy | 1:55 block |
| 3b | Initialize a working directory with `terraform init` | 1:55 block, Lab 1.2 step 2 |
| 3c | Validate a configuration with `terraform validate` | Lab 1.2 step 4 |
| 3g | Format code with `terraform fmt` | Lab 1.2 step 3 |
| 4a | Tell a resource block from a data source | Lab 1.2 step 6, Lab 1.3 |
| 4b | Explain how one resource refers to another (implicit dependency) | Lab 1.3 |

### Timing table

| Time | Min | Block | Material | Platform |
|---|---|---|---|---|
| 0:00 | 15 | Welcome, course map, laptop pre-check | Slides: title, agenda, objectives. `precheck.sh` | Free |
| 0:15 | 30 | IaC: what it is, clicking vs code, benefits (1a, 1b) | Slides: IaC | Free |
| 0:45 | 20 | Terraform and multi/hybrid cloud (1c) | Slides: Terraform and multi/hybrid cloud | Free |
| 1:05 | 35 | Providers, versions, lock file (2a, 2b) | Slides: providers. **Lab 1.1** `01-providers` | Free |
| 1:40 | 15 | **Break** | | |
| 1:55 | 30 | Workflow, vSphere provider and auth (3a, 3b) | Slides: workflow, vSphere provider and auth. **Lab 1.2** steps 1-2 (instructor demo) | vSphere |
| 2:25 | 35 | First VM on ESXi: resource vs data, fmt, validate, plan, apply (3c, 3g, 4a) | Slides: resource vs data, fmt/validate. **Lab 1.2** steps 3-6 | vSphere (ESXi) |
| 3:00 | 15 | Same VM through vCenter: folder, dependencies, destroy (4a, 4b) | **Lab 1.3** `03-vcenter-vm` (demo) | vSphere (vCenter) |
| 3:15 | 15 | Recap and quiz | Slides: recap and quiz. `quiz.md` | Free |

Split: about 115 min platform-free, 80 min vSphere.

### Materials

- Slide deck (sections in order: title, agenda, objectives; IaC; Terraform and multi/hybrid cloud; providers; workflow; vSphere provider and auth; resource vs data; fmt/validate; recap and quiz).
- Projector or screen share, with a terminal font large enough for the back row.
- Instructor laptop with Terraform 1.12.x or later (the same version as the class), git, govc, jq.
- Demo ESXi host (licensed ESXi 8, `192.168.100.31`) with its login, and the demo vCenter (`192.168.100.20`) with its login for Lab 1.3. The server has only 16 GB RAM and vCenter alone uses 14 GB (see section 5).
- Shared or printed sheet for each student: ESXi address, user, password, and a unique ID (`s01`, `s02`, ...). Students with the free nested ESXi or no ESXi use their own host or just watch (see "Lab platform" in `README.md`).
- This repository, cloned on every laptop.
- Offline fallback: provider mirror folder on a USB stick, and a screen recording of Lab 1.2 and Lab 1.3 (see section 5).

---

## 2. Before the session

### Day before

- [ ] The demo ESXi host is **licensed** (`govc license.ls`), not in lockdown mode, has `datastore1` and `VM Network`, and has at least 1 GB of free RAM per VM (`lab-setup-guide.md` Part A).
- [ ] Each student knows which ESXi they use (address, user, password) and has a unique ID. If students share a host, they have their own ESXi accounts (optional, `lab-setup-guide.md` A.6).
- [ ] Students know their platform: licensed ESXi (everything), free nested ESXi (everything except `apply`), or no ESXi (init, fmt, validate, then watch). Send the nested-ESXi guide to those who need it.
- [ ] Run Lab 1.2 against the ESXi host and Lab 1.3 against vCenter from start to finish from a laptop, including `destroy` (`lab-setup-guide.md` Part E). Note the exact vCenter datacenter and host names for Lab 1.3 (`govc ls /`, `govc find / -type h`). Note how long `apply` takes.
- [ ] If you run Lab 1.3 live, vCenter needs 10 to 15 minutes to boot. Plan when to start it so it is up by 3:00 and not earlier (it uses 14 GB of the 16 GB server).
- [ ] Laptops can reach `registry.terraform.io`, `releases.hashicorp.com` and `github.com`. The vSphere provider (`vmware/vsphere`) downloads from github.com, while `hashicorp/random` and `hashicorp/local` download from releases.hashicorp.com. If the venue network blocks any of them, prepare the provider mirror (section 5).
- [ ] Check that the latest `hashicorp/random` 3.x version is not 3.6.0. Lab 1.1 Part C relies on the lock file holding a version newer than the exact constraint you set. If 3.6.0 is the latest, use an older exact version in the demo (for example `= 3.5.1`), so that `init` still fails.
- [ ] Decide the class Terraform version and tell students before the day, so installs match.
- [ ] Prepare the offline kit: provider mirror on USB, screen recording of Lab 1.2 and Lab 1.3.
- [ ] Remind students to bring a laptop with Terraform, git and a code editor installed.

### 30 minutes before

- [ ] Projector works, terminal font is large, notifications are off.
- [ ] Log in to the ESXi Host Client (`https://192.168.100.31/ui`) and keep that tab ready. Confirm your demo VM name (`s01-vm01`) does not exist yet. Check free memory on the host.
- [ ] vCenter can stay **off** for now. Power it on about 20 minutes before 3:00 (or at the break), not earlier.
- [ ] In a terminal, export the four `VSPHERE_*` variables for the ESXi host. Run `govc about` (with the `GOVC_*` variables) to confirm the login.
- [ ] **Run the pre-check yourself:**

  ```bash
  cd labs/session-01/00-precheck
  bash precheck.sh
  ```

  Expect no `[FAIL]`. `[WARN]` for `aws`, `govc`, `jq` or `code` is acceptable; AWS credentials are not needed until Session 5.
- [ ] Run `terraform init` in `01-providers` once to warm the cache, then **delete `.terraform/`, `.terraform.lock.hcl`, `out/` and any state** so the live demo starts clean.
- [ ] Have a **spare finished VM** ready. In a separate directory (not `02-first-vm`, so it does not touch your demo state), apply Lab 1.2 under another student ID, so there is a VM visible in the Host Client and a successful `terraform output` to show anyone who falls behind.
- [ ] Open the slides, the lab READMEs and this guide side by side. Keep the screen recordings ready.
- [ ] Write the pre-check command on the board for students.

---

## 3. Run sheet

### 0:00 Welcome, course map, pre-check (15 min)

**Goal:** everyone knows the course shape and has a working laptop.

**Key talking points**
- Seven sessions, each 3:30. Exam is Terraform Associate 004, based on Terraform 1.12. Course mix is mostly VMware vSphere, some AWS (from Session 5), some platform-free.
- Today is platform-free and vSphere only. By the end, each student has a VM created by Terraform, and **keeps it for Session 2**.
- Show the agenda and objectives slides. Say how labs work: instructor demo first, then students follow.
- Exam needs no provider-specific knowledge, but the labs use vSphere because that is the team's day job.

**Live demo / activity**

Students run the pre-check from the repo:

```bash
cd labs/session-01/00-precheck
bash precheck.sh
```

Point out:
- `[PASS] terraform 1.12.x` (anything older than 1.12.0 shows `[FAIL]`).
- Three network checks: `registry.terraform.io`, `releases.hashicorp.com`, `github.com`. All three must pass.
- The ESXi check is skipped (`[WARN]`) unless `GOVC_URL` is set. If you want it tested now, hand out the ESXi address and user, and have students export `GOVC_URL`, `GOVC_USERNAME`, `GOVC_PASSWORD`, `GOVC_INSECURE=1`, then run `govc about`. Students without ESXi skip this check.
- Last line `Result: N passed, N warnings, N failed`. Exit status is non-zero if anything failed.

**Checkpoint question:** "Who has a `[FAIL]`?" (Fix each one now, before the break in the plan gets expensive.)

**Common student problems**

| Problem | Fix |
|---|---|
| `terraform` older than 1.12.0 | Install the class version. Give the exact download link or package command for their OS. |
| Cannot reach github.com or releases.hashicorp.com | Corporate proxy or firewall. Set `HTTPS_PROXY`, or use the provider mirror (section 5). Note the names for the instructor. |
| `git` missing | Install it. It is the only other required tool. |
| `govc` or `jq` missing | Only a warning. Needed later; install during the break if you can. |
| Script not executable | Run it with `bash precheck.sh`. |

**Timing tip:** do not spend more than 15 minutes. Any student still failing at 0:15 pairs with a neighbour and is fixed during the break.

---

### 0:15 IaC: what it is and why it helps (30 min)

**Goal:** students can explain IaC and its benefits in their own words, using their own clicking experience as the contrast.

**Slides for this block:** the IaC section (what it is, clicking vs code, benefits).

**Key talking points**
- IaC: describe infrastructure in text files, and a tool creates and changes it to match. The text is the source of truth.
- Start from their reality. Ask: "How do you build a VM today?" Then walk the clicking path in the vSphere Client or Host Client: wizard, datastore, network, hardware, 20 clicks. Compare with one `terraform apply`.
- Benefits (objective 1b):
  - **Idempotency / consistency:** running it again does not create a second VM. Terraform compares the desired state to what exists.
  - **Versioning:** the config lives in git. Every change has an author, a date, a diff.
  - **Review:** teammates review a pull request before anything changes. Clicking cannot be reviewed.
  - **Reuse:** the same code builds dev, test and prod. Modules (Session 5) package it.
  - **Documentation and speed:** the code is the documentation. Rebuilds are minutes, not days.
- Declarative vs imperative: you describe the end state, Terraform works out the steps.
- Be honest about limits: IaC does not make drift impossible. Someone can still click in vCenter or the Host Client. `plan` detects it (Session 2).

**Live demo (optional, 3 minutes):** show `labs/session-01/02-first-vm/main.tf` and ask which part answers "what size is the VM", "which datastore", "which network". Do not explain syntax yet.

**Checkpoint question:** "A colleague changes a VM's RAM in the vSphere Client. How would you know, and how would you undo it, in a team using IaC?" (Expected: `plan` shows the difference from the code; `apply` brings it back to the code. Covered in Session 2.)

**Common student problems**
- "We already use scripts / PowerCLI." See anticipated question 1. Do not argue; park it.
- Confusing "idempotent" with "never changes". Say: same input, same end result, no duplicate side effects.

**Timing tip:** if behind, drop the live demo and cut the "reuse" section to one sentence (modules come in Session 5). Keep the clicking vs code contrast and the benefit list, because 1a and 1b are tested directly.

---

### 0:45 Terraform and multi/hybrid cloud (20 min)

**Goal:** students understand that Terraform is one workflow for many platforms, and what that does and does not mean.

**Slides for this block:** Terraform and multi/hybrid cloud.

**Key talking points**
- One workflow (write, init, plan, apply) and one language (HCL) for vSphere, AWS, DNS, Vault, Kubernetes, and thousands of other services. Each one is a **provider** (next block).
- **Multi-cloud:** more than one public cloud. **Hybrid cloud:** on-prem plus cloud, for example vSphere plus AWS. **Service-agnostic:** not tied to one vendor or one kind of service.
- Important and tested: **the workflow is portable, the code is not.** A `vsphere_virtual_machine` is not an `aws_instance`. You learn one tool, but you still write platform-specific resources. (This is quiz question 2.)
- Practical hybrid example from the course: Session 5 builds a vSphere VM plus an AWS Route 53 DNS record in one configuration.
- Terraform is not only for VMs: DNS records, Vault policies, monitoring dashboards, SaaS settings.
- Providers are maintained by HashiCorp, by partners (such as VMware), or by the community.

**Checkpoint question:** "True or false: because Terraform is service-agnostic, I can change the provider block and my vSphere VM code will create an AWS instance." (False. Same workflow, different resource types.)

**Common student problems**
- Believing multi-cloud means "write once, run anywhere". Correct it as above.

**Timing tip:** this block is the easiest to shorten. Cut it to 10 minutes: one slide for the three terms, one for "workflow portable, code not", then take the checkpoint question. Give the time to Lab 1.1.

---

### 1:05 Providers and Lab 1.1 (35 min)

**Goal:** students install providers, read `init` output and the lock file, and see how version constraints and `required_version` behave.

**Slides for this block:** providers (plugin architecture, source address, versions and lock file). Keep the talk very short, because the lab parts alone fill the 35 minutes.

**Suggested budget**

| Minutes | What |
|---|---|
| 5 | Slides: plugin architecture, source address, version constraints, lock file |
| 10 | Part A: init, inspect `.terraform/`, lock file |
| 5 | Part B: apply, output |
| 15 | Part C: constraint, failing init, `-upgrade` |
| 5 | Part D: `required_version` (cut first if behind) |
| – | `terraform destroy` at the end of Part D, or as students leave for the break |

This adds up to 40 minutes for a 35-minute block. Expect to cut Part D, or cover it verbally, unless the slides go quickly.

**Key talking points**
- Terraform Core knows the language, state, graph and the workflow. It knows nothing about vSphere or AWS. **Providers are separate executables (plugins)** that Core talks to over RPC, and each one maps resources to a platform's API.
- Source address: `<hostname>/<namespace>/<type>`. `hashicorp/random` is short for `registry.terraform.io/hashicorp/random`. The hostname is implied.
- `required_providers` says which providers and which versions. `required_version` constrains Terraform itself, which is a different thing.
- `.terraform/` is a local cache: do not commit. `.terraform.lock.hcl` pins exact versions and checksums: **commit**.
- Constraint cheat sheet from the Lab 1.1 README: `= 3.6.0` exact; `>= 3.6` includes 4.x; `~> 3.6` means at least 3.6, below 4.0; `~> 3.6.0` means at least 3.6.0, below 3.7.0.

**Live demo commands (Part A)**

```bash
cd labs/session-01/01-providers
terraform version
terraform init
```

Point out in the `init` output:
- `Finding hashicorp/random versions matching "~> 3.6"...` (the constraint at work)
- `Installing hashicorp/random v3.x.y...` and `Installed ... (signed by HashiCorp)` (the exact version picked is the newest allowed)
- `Terraform has created a lock file .terraform.lock.hcl to record the provider selections it made above.`

```bash
find .terraform -maxdepth 6 | head -20
cat .terraform.lock.hcl
terraform providers
```

Point out:
- The path `.terraform/providers/registry.terraform.io/hashicorp/random/<version>/<os_arch>/`: hostname, namespace, type, version, platform. Each provider is a binary.
- Lock file entries: `provider "registry.terraform.io/hashicorp/random"` with `version`, `constraints` (copied from `versions.tf`) and `hashes`.
- `terraform providers` shows the tree of required providers.

**Part B**

```bash
terraform apply        # type "yes"
cat out/inventory.txt
terraform output server_name
```

Point out: the random pet name appears in the output and in the file. This shows two providers cooperating: `random_pet.server.id` feeds `local_file.inventory`.

**Part C (this is the key learning moment)**

1. In `versions.tf`, change the `random` constraint to `version = "= 3.6.0"` (or an older exact version, see "Day before").
2. `terraform init` **fails**. Read the error aloud: the locked version no longer matches the constraint, and Terraform tells you to use `-upgrade` to allow a new selection.
3. `terraform init -upgrade`, then `cat .terraform.lock.hcl`. The lock file now shows the exact older version.
4. Set the constraint back to `~> 3.6`, run `terraform init -upgrade` again.

Say clearly: plain `init` respects the lock file and never silently moves a provider. Only `-upgrade` (or `init` for a provider not yet locked) changes it.

**Part D:** set `required_version = ">= 99.0.0"`, run `terraform plan`, read the "Unsupported Terraform Core version" error, change it back.

Then clean up: `terraform destroy` and `yes`.

**Checkpoint questions**
1. "Which of these versions satisfies `~> 2.6`: 3.0.0, 2.5.9, 2.18.0, 1.99.0?" (2.18.0.)
2. "Why do we commit the lock file but not `.terraform/`?" (Lock file = exact versions and checksums for everyone. `.terraform/` = downloaded binaries, rebuilt by `init`.)

**Common student problems**

| Problem | Fix |
|---|---|
| `init` hangs or times out | Network or proxy to releases.hashicorp.com. Use the provider mirror (section 5). |
| `init` does not fail in Part C | The installed version already equals the exact constraint. Use an older exact version. |
| Student edits the wrong file | The constraint is in `versions.tf`, not `main.tf`. |
| Student sets `required_version` wrongly and `plan` still runs | They saved the wrong value or the wrong directory. `terraform version` and `cat versions.tf`. |
| `terraform destroy` asks for confirmation each time | Normal. Type `yes`. |
| Student commits `.terraform/` or state | `.gitignore` in the lab already excludes it. Check they did not run `git add -f`. |

**Timing tip:** Part D and the "Extra" section (filesystem mirror, `TF_PLUGIN_CACHE_DIR`) are the first to cut. Part D needs only 2 minutes if you do it as a demo on the projector instead of making everyone do it. Do not cut Part C: it is the only hands-on exposure to the lock file, and it is tested. Anything not finished is homework; Part D takes 5 minutes.

---

### 1:40 Break (15 min)

- Start the clock visibly. Return time on the screen.
- During the break: fix pre-check failures, check that every student's `VSPHERE_*` variables work and that they know which ESXi to use. Quick sanity: ask a few students to run `govc about` if installed.
- Write the Lab 1.2 environment variable block where students can see it.
- Instructor: set the demo environment variables again in your terminal and `cd labs/session-01/02-first-vm`.

---

### 1:55 Workflow and vSphere provider (30 min)

**Goal:** students know the five workflow steps, why vSphere credentials are never in code, and have a working `terraform init` on the Lab 1.2 directory. Credentials now point to the **ESXi host**, not vCenter.

**Slides for this block:** workflow; vSphere provider and auth. Then **Lab 1.2 steps 1 and 2**, as an instructor demo that the class follows on their own laptops.

**Suggested budget**

| Minutes | What |
|---|---|
| 12 | Slides: workflow |
| 8 | Slides: vSphere provider and auth |
| 5 | Lab 1.2 step 1: credentials and variables |
| 5 | Lab 1.2 step 2: `terraform init` |

**Key talking points: workflow**
- **Write** the config, **init** the directory, **plan** to see the changes, **apply** to make them, **destroy** to remove them. In the exam: init, plan, apply, destroy are commands; write is the human part.
- `init` is the first command in any new or cloned directory. It installs providers (and modules), sets up the backend, and writes the lock file. Safe to run repeatedly.
- `plan` is a preview and changes nothing. `apply` shows the plan again and waits for `yes`. (Session 2 goes deep on reading a plan.)
- `fmt` and `validate` fit between write and plan. Today's lab adds them.

**Key talking points: vSphere provider and authentication**
- The source is **`vmware/vsphere`**. Show `versions.tf` in `02-first-vm`: `source = "vmware/vsphere"`, `version = "~> 2.17"`. The old `hashicorp/vsphere` stopped at 2.12.
- Provider block is empty on purpose: `provider "vsphere" {}`. Credentials come from `VSPHERE_SERVER`, `VSPHERE_USER`, `VSPHERE_PASSWORD`, `VSPHERE_ALLOW_UNVERIFIED_SSL`.
- Why: code is committed and shared, so a password in `.tf` ends up in git history. Environment variables keep secrets out of the repo. (Full secrets story in Session 4 with Vault.)
- The same provider talks to an ESXi host or to vCenter. Only `VSPHERE_SERVER` changes. Today's Lab 1.2 uses the ESXi host directly, so there is no vCenter to install and no per-student account.
- `VSPHERE_ALLOW_UNVERIFIED_SSL=true` is for a lab ESXi host or vCenter with a self-signed certificate. Say it plainly: do not use it in production.

**Live demo commands (Lab 1.2 steps 1-2)**

```bash
cd labs/session-01/02-first-vm

export VSPHERE_SERVER="192.168.100.31"     # the ESXi host, not vCenter
export VSPHERE_USER="root"                 # or the ESXi user students were given
export VSPHERE_PASSWORD='********'
export VSPHERE_ALLOW_UNVERIFIED_SSL=true

cp terraform.tfvars.example terraform.tfvars
# set student to your ID; change datastore/network only if the host uses other names

terraform init
```

Tell students: type the password into your own terminal, never onto the projector or into chat. Hide the password (for example type it before sharing the screen, or use a shell with history disabled).

Point out in the `init` output:
- `Finding vmware/vsphere versions matching "~> 2.17"...`
- `Installing vmware/vsphere v2.x.y...` followed by an `Installed` line with a signer.
- The lock file message again. Run `cat .terraform.lock.hcl` and note `registry.terraform.io/vmware/vsphere`.
- Mention: this download comes from `github.com`, while the `random` and `local` providers earlier came from `releases.hashicorp.com`. That is why the pre-check tests both.

Then answer the README's question: why is `terraform.tfvars` in `.gitignore`? (It holds environment-specific values, and a habit of never committing `*.tfvars` protects you when a file does contain a secret.)

**Checkpoint question:** "Where is the vSphere password stored in this configuration?" (Nowhere in the files. It is in the shell environment of the person running Terraform.)

**Common student problems**

| Problem | Fix |
|---|---|
| Password with special characters breaks the export | Use single quotes: `export VSPHERE_PASSWORD='...'`. |
| `export` done in another terminal tab | Variables are per shell. Re-export in the tab where Terraform runs. |
| `terraform.tfvars` still has `s01` for everyone | Each student must set their own `student` ID. On a shared host, two students with the same ID get `The name '...' already exists`. |
| `init` cannot find provider `vmware/vsphere` | Network to github.com is blocked. Use the provider mirror. |
| Student copied the source as `hashicorp/vsphere` | Fix to `vmware/vsphere`. Do not edit `versions.tf` otherwise. |
| `x509: certificate signed by unknown authority` (shows later at plan time) | `VSPHERE_ALLOW_UNVERIFIED_SSL` is not set in that shell. |
| Student has no ESXi | `init` works without one. Let them follow on the projector. |

**Timing tip:** shorten the workflow slides to the five commands and one sentence each (Session 2 repeats them in depth). Step 1 and 2 must stay, because everything after depends on a working `init`. If students are slow with credentials, do step 2 on the projector and have them catch up while you move on.

---

### 2:25 First VM on ESXi: resource vs data, fmt, validate, plan, apply (35 min)

**Goal:** every student with a licensed ESXi has a VM, and everyone can say which blocks are data sources and which are resources, what `fmt` and `validate` do, and what `validate` cannot catch.

**Slides for this block:** resource vs data; fmt/validate. Then **Lab 1.2 steps 3 to 6**.

**Suggested budget**

| Time | Min | What |
|---|---|---|
| 2:25 | 4 | Slides: resource vs data (tour the files) |
| 2:29 | 2 | Slides: fmt/validate |
| 2:31 | 4 | Step 3: `fmt` |
| 2:35 | 8 | Step 4: `validate`, break it on purpose |
| 2:43 | 10 | Step 5: `plan`, `apply` (a few seconds on a licensed host) |
| 2:53 | 5 | Step 6: resource vs data discussion |
| 2:58 | 2 | Buffer |

Start `apply` early. It takes seconds on a licensed host, so the time goes on reading the plan, not on waiting.

**Why no clone, no template?** Cloning needs vCenter, a template, guest customization and DHCP. Building the VM from scratch needs only an ESXi host: 1 vCPU, 512 MB, an empty 8 GB thin disk and no OS. It starts in seconds, uses little RAM (the instructor server has 16 GB), and the VM is only a target for Terraform. Cloning comes later in the course. Say this once, early; it is a common question (section 4).

**Key talking points: file tour** (3 minutes, before students touch anything)
- `versions.tf` (providers), `provider.tf` (empty block), `variables.tf` (inputs), `data.tf` (reads), `main.tf` (the VM), `outputs.tf` (printed after apply).
- Open `data.tf`. Four data sources: datacenter, datastore, network and host. They **read** existing objects. Terraform never creates, changes or deletes them.
- Connected straight to ESXi, `data "vsphere_datacenter" "dc" {}` has **no arguments** and `data "vsphere_host" "esxi"` needs no name. An ESXi host has exactly one datacenter (`ha-datacenter`) and one host (itself), so there is nothing to name. The VM goes into the host's root resource pool: `data.vsphere_host.esxi.resource_pool_id`. Through vCenter (Lab 1.3) you must name them.
- Open `main.tf`. One `resource "vsphere_virtual_machine" "vm"`. It references data sources: `data.vsphere_datastore.ds.id` and so on. The `data.` prefix tells you where a value comes from.
- Address format: resource `vsphere_virtual_machine.vm`, data source `data.vsphere_datastore.ds`.
- `wait_for_guest_net_timeout = 0`: there is no OS, so no guest network to wait for. Without it, apply would wait.

**Step 3: fmt**

```bash
terraform fmt -check       # lists the files that need formatting; exit status is non-zero
terraform fmt -diff        # shows the changes and applies them
terraform fmt -check       # now silent, exit status 0
```

Point out:
- The first command prints `outputs.tf`. That file is badly formatted on purpose.
- `-diff` shows the diff **and** rewrites the file. `-check` alone never rewrites.
- `fmt` changes layout only: indentation and aligned `=`. It never changes what the code means. `-recursive` handles subfolders. `fmt -check` is the usual CI gate.
- `fmt` needs no init and no credentials.

**Step 4: validate**

```bash
terraform validate
```

Point out `Success! The configuration is valid.`. Then break things one at a time, running `validate` after each and undoing it:

| # | Change | Expected |
|---|---|---|
| 1 | `data.vsphere_datastore.ds.id` becomes `data.vsphere_datastore.dss.id` in `main.tf` | Error: reference to an undeclared resource |
| 2 | Delete the `}` closing the `disk` block | Error: unclosed block (syntax) |
| 3 | `num_cpus = 1` becomes `num_cpus = "one"` | Error: wrong type for the argument |
| 4 | `datastore` in `terraform.tfvars` set to a name that does not exist | **`Success!`. Validate does not catch it.** |

Ask: "Which one got through, and why?" Answer: #4. `validate` checks syntax, references and types against the provider schema. It never calls ESXi. Only `plan` finds out that the datastore does not exist, when the `vsphere_datastore` data source tries to read it. Fix #4 before continuing. Mention that `validate` needs `init` to have run (it needs the provider schemas) but needs **no credentials**. Students with no ESXi can do this whole step.

**Step 5: plan and apply**

```bash
terraform plan
terraform apply            # review the plan, then type "yes"
```

Point out in the plan:
- The only `+ create` is `vsphere_virtual_machine.vm`. Data sources are read during the plan and are not creates.
- Values marked `(known after apply)` such as `id`, `moid` and `uuid`: ESXi assigns them when the VM exists, so Terraform cannot know them earlier.
- `Plan: 1 to add, 0 to change, 0 to destroy.`

When it finishes:

```bash
terraform output
terraform output -raw vm_power_state
terraform plan             # No changes
```

Show the VM in the Host Client (*Virtual Machines*). Open its console: powered on, no operating system, which is correct. Confirm the name `<student>-vm01`.

**Teaching moment: the free ESXi apply error.** A student with the nested free ESXi will see `init`, `validate` and `plan` succeed, and then `apply` fail:

```text
current license or ESXi version prohibits execution of the requested operation
```

Do not treat it as a failure; use it. Explain:
- The free licence makes the ESXi API **read-only**. Reading works; creating does not.
- `plan` only needs reads: the data sources read the datastore and network, and Terraform compares that to the code. That is why `plan` works.
- `apply` needs a **write** (create a VM). That is a `resource` doing its job, and the licence blocks it.
- So the error draws the line between **data** (read) and **resource** (write) from a different direction. This is objective 4a again. It also shows that a successful `plan` does not guarantee a successful `apply`.

Students with no ESXi, or only the free ESXi, watch the instructor's apply on the projector and follow the output.

**Step 6: resource vs data (discussion)**

Use the comparison table: resource = create and manage (create, update, destroy), data = read only. Ask: "What happens to the datastore when you run `terraform destroy`?" Answer: nothing. A data source only reads. Do **not** run `destroy` for Lab 1.2 today, since the VM is kept for Session 2.

**Checkpoint questions**
1. "Which of the four broken changes did `validate` miss, and why?"
2. "You run `terraform destroy`. What happens to the datacenter, datastore and network?" (Nothing. They are data sources.)
3. "What does `(known after apply)` mean?"
4. "Why does `plan` work on the free ESXi but `apply` does not?" (Plan reads. Apply writes. The free licence blocks writes.)

**Common student problems**

| Error / symptom | Likely cause and fix |
|---|---|
| `x509: certificate signed by unknown authority` | `VSPHERE_ALLOW_UNVERIFIED_SSL=true` missing in this shell. |
| `Cannot complete login due to an incorrect user name or password` | Wrong user or password, or the host is in lockdown mode. |
| `datastore '...' not found` | Typo in `terraform.tfvars`, or a different datastore name on this host. Check *Storage* in the Host Client. A leftover from Step 4 change #4 is common: revert it. |
| `network '...' not found` | The port group name is case-sensitive: `VM Network`. |
| `The name '...' already exists` | Two students on the same host used the same `student` ID. |
| `current license or ESXi version prohibits execution of the requested operation` | Free ESXi: expected. See the teaching moment above. |
| Power-on fails with `insufficient memory` | The host is out of RAM. See section 5, "VM won't power on". |
| `validate` complains about unknown provider or missing schema | They skipped `init`, or ran it in the wrong directory. |
| Student leaves the broken line from Step 4 in place | Run `terraform fmt -check` and `terraform validate` again before `plan`. |
| `terraform.tfvars` missing: Terraform prompts for each variable | They skipped `cp terraform.tfvars.example terraform.tfvars`. |

**Timing tip (if behind)**
1. Trim Step 4 to changes 1 and 4 only (the contrast between "caught" and "missed" is the lesson). Do 2 and 3 as a 1-minute demo on the projector.
2. Skip the "Extra exercise" in the Lab 1.2 README.
3. Run Step 6 while the `apply` outputs are on screen, not afterwards.
4. If many students are stuck on credentials, do the apply on the projector and let them finish after the recap.

Do not cut Step 4 change 4 or the resource vs data question: both are tested (3c, 4a). If this block overruns, shorten Lab 1.3 to a demo of 10 minutes; do not take time from the recap.

---

### 3:00 Lab 1.3: the same VM through vCenter (15 min)

**Goal:** students see what vCenter adds on top of an ESXi host (a named datacenter, a chosen host, folders) and how Terraform orders two resources by following a reference. Objectives 4a and 4b.

**Instructor demo.** Hands-on only for students who have their own vCenter. Everyone else watches.

**Before you start:** vCenter (`192.168.100.20`) must be on and answering (it takes 10 to 15 minutes to boot, and uses 14 GB of the server's 16 GB). Run this lab **last**. If other VMs are running on the host, power off what you can first. Destroy the Lab 1.3 VM right after the demo.

**Suggested budget**

| Minutes | What |
|---|---|
| 3 | Step 1: credentials now point to vCenter; the names to fill in |
| 3 | Step 2: read the code, the comparison table |
| 6 | Step 3: init, plan, apply (two resources) |
| 3 | Step 4: destroy |

**Step 1: credentials**

```bash
cd labs/session-01/03-vcenter-vm
export VSPHERE_SERVER="192.168.100.20"                  # vCenter
export VSPHERE_USER="administrator@vsphere.local"
export VSPHERE_PASSWORD='********'
export VSPHERE_ALLOW_UNVERIFIED_SSL=true
cp terraform.tfvars.example terraform.tfvars            # datacenter and host as listed in the vSphere Client
```

Same variable names, different values. Remind students to re-export their ESXi credentials before returning to Lab 1.2.

**Step 2: the comparison**

Put the table from the Lab 1.3 README on screen and walk through it:

| | Lab 1.2: ESXi directly | Lab 1.3: vCenter |
|---|---|---|
| `VSPHERE_SERVER` | the ESXi host | the vCenter |
| Datacenter | `data "vsphere_datacenter" "dc" {}` (the built-in `ha-datacenter`) | named: `name = var.datacenter` |
| Host | `data "vsphere_host"` without a name (the only host) | must be named: `name = var.host` |
| VM folders | none | `vsphere_folder`, created by Terraform |
| VM ID (`moid`) | a number, e.g. `3` | `vm-1042` |
| Clone, customization, tags, OVF | not available | available (later in the course) |

Key point: vCenter manages many hosts and datacenters, so "the default one" no longer exists and data sources must look things up **by name**. Same provider, same resource type (`vsphere_virtual_machine`), different data sources.

In `main.tf`, point at `folder = vsphere_folder.lab.path`. That reference is the dependency.

**Step 3: init, plan, apply**

```bash
terraform init
terraform validate
terraform plan             # Plan: 2 to add
terraform apply
```

Point out:
- **Two** resources: `vsphere_folder.lab` and `vsphere_virtual_machine.vm`.
- In the apply output the folder is created **before** the VM. Nobody wrote "create the folder first". Terraform saw that the VM's `folder` argument refers to `vsphere_folder.lab.path`, so it builds a graph and orders the work. This is an **implicit dependency** (4b). `depends_on` is the explicit version, covered later.
- In the vSphere Client, *VMs and Templates*: folder `sNN-lab` holds `sNN-vc-vm01`.

**Step 4: destroy**

```bash
terraform destroy
```

Point out the **reverse order**: the VM first, then the folder (a folder that still holds a VM cannot be deleted). Terraform uses the same graph backwards.

Ask: "The datacenter, host, datastore and network are still there after `destroy`. Why?" (They are `data` sources: Terraform only read them.)

Run `destroy` right away, even if you are tight on time: the 512 MB VM is only a comparison and the server's memory is overcommitted.

**Common student problems**

| Error / symptom | Likely cause and fix |
|---|---|
| `datacenter '...' not found` | The name is case-sensitive; copy it from the vSphere Client. |
| `host '...' not found` | Use the host exactly as listed in vCenter (often the IP address). |
| `NoPermission` ... `Folder.Create` | The vCenter user cannot create folders. Use the administrator account for the demo. |
| `Cannot complete login` | ESXi credentials still exported; vCenter users look like `user@vsphere.local`. |
| Power-on fails with `insufficient memory` | vCenter uses 14 GB of 16 GB. See section 5. |
| vSphere Client does not load | vCenter is still booting. Wait, or play the recording. |

**Timing tip:** if short on time, skip Step 1 (set it up before the break) and do Steps 2 to 4 on the projector. If vCenter is not up, play the recording. Do not cut the apply/destroy order: it is the only place where the dependency graph is visible today.

---

### 3:15 Recap and quiz (15 min)

**Goal:** lock in the day's exam objectives and hand over to Session 2.

**Slides for this block:** recap and quiz.

**Suggested budget:** 10 min quiz, 5 min handover (section 6).

**Key talking points (recap)**
- IaC benefits: version control, review, repeatability. It does not make drift impossible.
- Providers are plugins, found by source address, pinned by version constraints, locked by `.terraform.lock.hcl` (committed).
- Workflow: write, init, plan, apply, destroy. `fmt` and `validate` need no credentials; `validate` needs `init` but never calls an API.
- `resource` creates and manages; `data` reads.
- A reference from one resource to another creates an implicit dependency: create order forwards, destroy order backwards (Lab 1.3).

**Quiz:** [`quiz.md`](quiz.md) has 8 questions and a collapsible answer key. Mapping to objectives and the correct answers:

| Q | Obj | Topic | Answer |
|---|---|---|---|
| 1 | 1a, 1b | Benefit of IaC over clicking | A |
| 2 | 1c | Service-agnostic does not mean portable code | B (False) |
| 3 | 2a | `~> 2.6` | C (2.18.0) |
| 4 | 2a | Lock file facts (choose two) | A and C |
| 5 | 2a, 2b | Namespace change `hashicorp/vsphere` to `vmware/vsphere` | B |
| 6 | 3a, 3b, 2b | What `init` does | B |
| 7 | 3c, 3g | fmt and validate without init or credentials (choose two) | A and C |
| 8 | 4a | Data source and `destroy` | C |

Ask for a show of hands per question before revealing. Spend the time on wrong answers: Q4 (lock file is providers only, not modules), Q7 (what needs `init`) and Q5 (the namespace move) are the usual misses. Plan says 5 exam-style questions; if time is short, run Q3, Q4, Q6, Q7 and Q8 and hand out the rest as homework.

**Common student problems**
- Q4 option B: students think the lock file also pins modules. It does not.
- Q7 option B: students assume `validate` works before `init`. It needs the provider schemas, so `init` first.

**Timing tip:** if Lab 1.2 or Lab 1.3 overran, run only four questions (Q3, Q4, Q7, Q8) and send the full `quiz.md` as homework. Never skip the handover.

---

## 4. Anticipated questions

1. **How is Terraform different from Ansible or PowerCLI?**
   Terraform is declarative and tracks state: you describe the end result and it works out create, change or destroy. PowerCLI is imperative scripting: you write the steps, and a second run can duplicate things unless you add checks. Ansible can be either, but is mostly used for configuring what runs *inside* machines. They combine well: Terraform builds the VM, then Ansible or cloud-init configures it.

2. **Why do we commit `.terraform.lock.hcl`?**
   It records the exact provider versions and checksums chosen by `init`. If it is committed, teammates and CI install the same versions, so a new provider release cannot change a plan unexpectedly. `.terraform/` is only a local cache, so it is not committed. Lock file changes only on `init` (for example `-upgrade`), never on `plan`.

3. **Why do credentials go in environment variables and not in the provider block?**
   Because `.tf` files are committed, reviewed and shared, and a password in them is leaked forever in git history. Environment variables live only in the shell of whoever runs Terraform. Session 4 shows the next step: a secrets store (Vault).

4. **What is the difference between a data source and a resource?**
   A resource block creates and manages an object, and Terraform owns its lifecycle, including destroy. A data source reads an object that already exists and never changes or destroys it. The data source address starts with `data.`.

5. **Why does `terraform validate` pass when the datacenter name is wrong?**
   `validate` only checks syntax, references and types against provider schemas, and it makes no API calls. Whether the datastore or datacenter exists is only known when the data source reads ESXi or vCenter during `plan`.

6. **Why did the provider move to `vmware/vsphere`? Do I need to change anything?**
   The provider is now published in the `vmware` namespace. `hashicorp/vsphere` was frozen at 2.12 and receives no updates; current releases (2.18 now) are only under `vmware/vsphere`. For new work, use `vmware/vsphere`. For an existing project on the old address, change the `source`, run `terraform init -upgrade`, and if the state references the old provider, run `terraform state replace-provider hashicorp/vsphere vmware/vsphere`. It downloads from github.com, while HashiCorp's own providers download from releases.hashicorp.com.

7. **Is OpenTofu the same thing? Will it work for the exam?**
   OpenTofu is a separate, community-governed fork of Terraform that is a different tool from HashiCorp Terraform. The exam covers HashiCorp Terraform (1.12), so this course uses Terraform.

8. **What does `~>` mean?**
   It allows only the right-most number to increase. `~> 3.6` means at least 3.6 and below 4.0; `~> 3.6.0` means at least 3.6.0 and below 3.7.0. `>= 3.6` has no ceiling.

9. **What is the difference between `required_version` and a provider version constraint?**
   `required_version` limits which Terraform CLI versions may run this configuration. A `version` inside `required_providers` limits the provider plugin version.

10. **Can I run `apply` straight away without `plan`?**
    Yes. `apply` generates a plan and shows it first, then asks for `yes`. `plan` alone is a safe preview that changes nothing. A saved plan with `-out` is covered in Session 2.

11. **Can I use the same code for AWS?**
    The workflow and language are the same, but the resources are not: `vsphere_virtual_machine` has no AWS version. You would write an `aws_instance` instead. This is quiz question 2.

12. **What if I run `apply` twice?**
    The second run finds the real infrastructure already matches the code, and reports no changes (idempotency). That is the "extra exercise" in Lab 1.2.

13. **Where is the information about my VM stored?**
    In the **state file** (`terraform.tfstate`, created in the lab directory). It maps config to real objects. Session 2 reads it in detail. For now: do not delete or edit it, and do not commit it.

14. **What if someone changes the VM by hand in the Host Client or vCenter?**
    That is drift. `plan` will show the difference. Session 2 covers drift and `-refresh-only`.

15. **Why not use the admin account for the lab?**
    On a shared ESXi host it is better that each student has their own account, so a mistake or a leaked password does not affect everyone. For Session 1 the built-in Administrator role on the host is enough; there is no vCenter role design yet.

16. **Why don't we clone a template? Why is the VM empty?**
    Cloning needs vCenter, a prepared template, guest customization and DHCP. That is a lot of setup and it needs a lot of RAM on the demo server (16 GB, with vCenter taking 14 GB). Lab 1.2 builds the VM from scratch on an ESXi host: 1 vCPU, 512 MB, an empty 8 GB disk, no OS. It teaches the same Terraform concepts (providers, data, resource, workflow) and starts in seconds. Cloning and OS setup come later in the course.

17. **What does vCenter add? Why do we use it in Lab 1.3?**
    vCenter manages many hosts and clusters as one inventory. Through it you get named datacenters and hosts, folders, clusters, clone and customization, tags and OVF deployment. A standalone ESXi host has one built-in datacenter, one resource pool and no folders. The Terraform provider is the same; the data sources need names instead of empty blocks, and you can create folders.

18. **Can we use the free ESXi?**
    For everything except `apply`. The free licence makes the API read-only: `init`, `fmt`, `validate` and `plan` work, and `apply` fails with `current license or ESXi version prohibits execution of the requested operation`. Students with it follow the instructor's `apply`. A free ESXi also cannot be added to vCenter, so Lab 1.3 needs a licensed host.

---

## 5. If things break

### ESXi unreachable, lockdown mode, or licence problems

- Check first from your own laptop: browser to the Host Client (`https://192.168.100.31/ui`), then `govc about`. Tell the class what is happening within a minute.
- **Lab 1.1 needs no ESXi** (only `random` and `local`), so run it as planned if the outage hits before 1:40.
- **Unreachable:** check power, network and the IP address. Students can still run `init`, `fmt` and `validate` (everything that does not call the API).
- **Lockdown mode** (login fails with `Cannot complete login`): the host is managed by a vCenter that blocks direct logins. Disable lockdown in the Host Client or vSphere Client (host > *Configure > Security Profile*), or use vCenter for the demo.
- **Licence:** `govc license.ls`. If the host is on the free licence or an expired evaluation, `apply` fails with `current license or ESXi version prohibits execution of the requested operation`. Fix the licence; if you cannot, run the demo `apply` from the recording or the spare VM, and use the error as a teaching moment (2:25 block).
- If it hits during Lab 1.2:
  1. Switch to the **recorded demo**: play the screen recording of Lab 1.2 on the projector, pausing at `init`, `fmt`, `validate` (including the failing and missed cases), `plan` and `apply`.
  2. Students can still do `terraform fmt` (Step 3) and, after `terraform init`, `terraform validate` (Step 4 changes 1 to 3). Change 4 and `plan` need ESXi.
  3. Run the resource vs data discussion (Step 6) and the quiz as normal.
  4. Reschedule the live apply: tell students to run Lab 1.2 later in the week, and re-check that every student has a VM before Session 2.
- Show your spare finished VM output and the Host Client from the spare run if it was done before the outage.

### Out of memory on the 16 GB server

- vCenter alone takes about 14 GB. With vCenter on, ESXi has very little room, and memory is overcommitted.
- Keep vCenter **off** until the 3:00 block. Lab 1.2 does not need it.
- If power-on fails with `insufficient memory`: power off other VMs on the host; power off vCenter if you are still in Lab 1.2; reduce the number of student VMs on the instructor server (students can use their own licensed host if they have one).
- During Lab 1.3, only the demo VM runs. Destroy it immediately after the demo, then power off vCenter if nothing else needs it.
- If vCenter will not boot or is very slow, play the Lab 1.3 recording. Lab 1.3 is a comparison, not a prerequisite for Session 2.

### No internet, or a blocked provider download

- Symptom: `terraform init` hangs, or says it cannot query available provider packages or cannot download from the registry/github.com.
- Fix with a **provider mirror**, prepared in advance on a laptop with internet:

  ```bash
  cd labs/session-01/01-providers
  terraform providers mirror ./mirror          # random and local
  cd ../02-first-vm
  terraform providers mirror ./mirror          # vmware/vsphere
  ```

  Put both mirrors into one folder structure on a USB stick (the mirror layout is `<hostname>/<namespace>/<type>/...`, so the two do not clash). On each student laptop, add a `provider_installation` block to `~/.terraformrc` (or the file named in `TF_CLI_CONFIG_FILE`):

  ```hcl
  provider_installation {
    filesystem_mirror {
      path = "/path/to/mirror"
    }
  }
  ```

  Then `terraform init` installs from the folder. Use the same Terraform version and OS/architecture as the class, or run `terraform providers mirror -platform=<os_arch>` for each platform that is in the room.
- Alternative: `TF_PLUGIN_CACHE_DIR` shares one download cache, which also helps if the network is slow. It does not help if nothing has ever been downloaded.
- If only github.com is blocked, then only the vSphere provider is affected: Lab 1.1 can run normally.
- Pre-check catches this. Do not wait until 1:55 to find out.

### VM won't power on: insufficient memory

- Symptom: `terraform apply` creates the VM and then fails at power-on with an error about insufficient memory (or the VM stays powered off).
- Cause: the host has too little free RAM. Each lab VM takes 512 MB plus overhead. On the 16 GB instructor server, vCenter takes 14 GB.
- Fix: power off other VMs (or vCenter) to free memory, then run `terraform apply` again. Terraform finds the VM in state and retries the power-on; it does not create a second VM.
- Do not delete the VM by hand and carry on. If the retry fails, `terraform destroy` it (or ask the instructor to run `govc vm.destroy <name>`) and start again.
- Do not press Ctrl+C during `apply`. Interrupting can leave a half-created VM and a state mismatch.
- A student who falls behind: let them pair with a neighbour, or show your spare finished VM and `terraform output`, then have them finish after the recap. They **must** have their own VM and state before Session 2 (students with a free or no ESXi are the exception: they have no VM to keep, and follow along from the instructor's demo in Session 2).

---

## 6. Handover to Session 2

**Students keep their Lab 1.2 VM** (`<student>-vm01`, on the ESXi host). The Lab 1.3 VM was destroyed. Session 2 starts directly from the Lab 1.2 VM: reading a plan, changing CPU and RAM, replacement vs in-place changes, destroy, then state and drift.

**Say before closing**
- Do not run `terraform destroy`.
- Do not delete the lab directory, or `terraform.tfstate` inside it. The state file is the link between the code and the VM. Without it, Terraform will try to create a second VM.
- Do not rename or delete the VM in the Host Client.
- Do not commit `terraform.tfvars`, `*.tfstate` or `.terraform/`. The lab `.gitignore` files already cover them.
- Keep the same laptop and the same Terraform version, if possible.

**Student check before leaving** (each student shows you, or does it quickly):

```bash
cd labs/session-01/02-first-vm
terraform output                 # shows vm_name, vm_power_state, vm_moid, vm_uuid
terraform plan                   # should say: No changes. Your infrastructure matches the configuration.
```

- `terraform output` must show `vm_name`, `vm_power_state`, `vm_moid` and `vm_uuid`.
- `terraform plan` ending with "No changes" confirms that the state and the VM agree. If it shows changes, note why (often a changed `terraform.tfvars`) and sort it out now.
- The VM `<student>-vm01` is visible in the ESXi Host Client under *Virtual Machines*.
- `terraform fmt -check` and `terraform validate` pass.

**Instructor tasks after the session**
- [ ] Write down which students did not finish and schedule catch-up before Session 2.
- [ ] Note which errors came up most and add them to your troubleshooting list.
- [ ] Check that every student's Lab 1.2 VM exists, is powered on, and that no student ended with a broken half-created VM.
- [ ] Check that every Lab 1.3 VM and `sNN-lab` folder is destroyed (`lab-setup-guide.md` Part F), and power vCenter off if you do not need it.
- [ ] Share the quiz answers for anyone who did not finish, and the homework (the rest of `quiz.md`, Lab 1.1 Part D, the Lab 1.2 extra exercise, and Lab 1.3 for students who have a vCenter).
- [ ] Confirm the date and the pre-reading (none required) for Session 2.

**One-line preview for the class:** "Next time we change this VM, read what Terraform plans to do about it, and look inside the state file that remembers it."
