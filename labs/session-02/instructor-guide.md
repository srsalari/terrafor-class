# Session 2 Instructor Guide: Core workflow & state

Terraform Associate (004) course. The exam is based on Terraform 1.12, and the class pins one exact 1.12.x or later.
Session length: 3:30 (3:15 teaching, one 15-minute break). Platform: vSphere only (the team's own licensed ESXi host). No AWS in this session.
Students are **online** and run Terraform **from their own laptops** against the **team's own ESXi server at their workplace** (shared host, unique student prefix, no vCenter needed). All labs run in **one folder**, `vm-lab`, which continues with the VM from Lab 1.2.

Related files: [`README.md`](README.md) (student timeline), [`lab-2.1-plan-apply.md`](lab-2.1-plan-apply.md), [`lab-2.2-destroy.md`](lab-2.2-destroy.md), [`lab-2.3-state.md`](lab-2.3-state.md), [`lab-2.4-drift.md`](lab-2.4-drift.md), [`vm-lab/`](vm-lab), [`solution/main.tf`](solution/main.tf), [`smoke.sh`](smoke.sh), [`lab-setup-guide.md`](lab-setup-guide.md), [`quiz.md`](quiz.md).

> **Not verified on real hardware.** Three things in these labs were written from documentation and have not yet run against a real ESXi host. [`smoke.sh`](smoke.sh) tests all of them. Run it the day before (section 2) and correct the timings and wording in this guide from what you see.
>
> 1. How long the CPU/RAM change takes with `shutdown_wait_timeout = 1` on a VM **without VMware Tools** (Lab 2.1 step 3). The labs say "about 1 minute at `Still modifying...`". That is an expectation, not a measurement.
> 2. `govc vm.change -vm <name> -annotation "..."` (Lab 2.4 step 1). Check `govc vm.change -h` for the flag on your govc version.
> 3. The `datacenter` and `host` variables, which default to `null`, against a **vCenter** (the lockdown fallback). They are meant to be ignored on a standalone ESXi host and used on vCenter. Only the standalone path is tested.

---

## 1. At a glance

### Objectives covered

| Obj | What the student can do afterwards | Where |
|---|---|---|
| 3d | Read a plan: `+`, `-`, `~`, `-/+`, the summary line. Save a plan with `-out`, read it with `terraform show` and `show -json` | 0:00 block, Lab 2.1 steps 1-2 |
| 3e | Apply a saved plan and a live plan. Tell an in-place update from a replacement. Force a replacement with `-replace` | 0:35 block, Lab 2.1 steps 3-5 |
| 3f | Destroy everything, preview with `plan -destroy`, remove one resource by deleting its code, and say why `-target` is for emergencies | 1:10 block, Lab 2.2 |
| 2d | Explain what the state is for: mapping, metadata, performance | 1:45 block, Lab 2.3 step 5 |
| 6a | Name the default backend (local), its file `terraform.tfstate`, and what the backup file is | 1:45 block, Lab 2.3 step 1 |
| 7b | Inspect state with `state list`, `state show`, `show`, `show -json`, `output` | 2:15 block, Lab 2.3 |
| 6d | Explain drift. Use `plan -refresh-only` and `apply -refresh-only`. Use `ignore_changes` on purpose | 3:00 block, Lab 2.4 |

### Timing table

| Time | Min | Block | Material | Platform |
|---|---|---|---|---|
| 0:00 | 35 | Move the VM into `vm-lab`; reading a plan, saved plans (3d) | Slides: plan symbols. **Lab 2.1** steps 0-2 | vSphere (ESXi) |
| 0:35 | 35 | Apply: in-place vs replacement, `-replace` (3e) | Slides: in-place vs replace. **Lab 2.1** steps 3-5 | vSphere (ESXi) |
| 1:10 | 20 | Destroy, `plan -destroy`, `-target` with care (3f) | **Lab 2.2** | vSphere (ESXi) |
| 1:30 | 15 | **Break** | | |
| 1:45 | 30 | How Terraform uses state; the local backend (2d, 6a) | Slides: state | Free (talk) |
| 2:15 | 45 | Inspect state from the CLI (7b) | **Lab 2.3** | vSphere (ESXi) |
| 3:00 | 25 | Drift: `-refresh-only`, `ignore_changes` (6d) | **Lab 2.4** | vSphere (ESXi) |
| 3:25 | 5 | Recap | `quiz.md` | Free |

Split: about 30 min talk, 165 min lab. Almost everything is hands-on in one folder, so a student who falls behind early stays behind. Use the catch-up rules in each block.

### Materials

- Slide deck (sections in order: plan symbols; in-place vs replace; destroy and `-target`; state; recap). The state talk at 1:45 has its own talking points below.
- Projector or screen share, with a terminal font large enough for the back row.
- Instructor laptop with Terraform 1.12.x or later (the same version as the class), git, govc, jq.
- Instructor demo host: your own licensed ESXi (HP server, 16 GB RAM, `192.168.100.31`). **Keep vCenter off**: it takes about 14 GB and Session 2 does not need it.
- For each student: the workplace ESXi address, user, password (or the name of the person who gives it out), and a unique ID (`s01`, `s02`, ...). Students with only the free nested ESXi follow the demo for apply and destroy (see section 5).
- This repository, cloned on every laptop, with the Session 1 folder `labs/session-01/02-first-vm` **including** `terraform.tfstate` and `terraform.tfvars`.
- Fallback: a screen recording of Labs 2.1 and 2.4 from your own run of `smoke.sh` steps.

---

## 2. Before the session

### Day before

- [ ] **Run [`smoke.sh`](smoke.sh) against your demo ESXi host** from a laptop (`lab-setup-guide.md` Part A). It runs every risky step of the four labs on throwaway `zz99-*` VMs in a temporary folder and cleans up. Needs `terraform`, `jq`, `govc` and the `VSPHERE_*` variables. Paste back or note:
  - **How long the CPU/RAM change takes** (the output line `--- took Ns` after "CPU 2 / RAM 1024"). Update the timing in the 0:35 block and the lab text if it is not about a minute.
  - Whether `govc ok` appears in the Lab 2.4 section (the `-annotation` flag works on your govc and ESXi).
  - That the `-replace` step prints a new `moid`, and that the stale-plan error appears.
- [ ] The workplace ESXi host is **licensed** (`govc license.ls`), not in lockdown mode (or you have the vCenter name, datacenter and host for the fallback), and has free RAM and disk for the class (`lab-setup-guide.md` Part B). Budget: each student needs up to 1.25 GB of RAM at once (VM 1 GB after the resize, plus the 256 MB `test` VM in Lab 2.2).
- [ ] Each student has an ESXi user with a role that can create, reconfigure, power and delete VMs (or `root`), and a **unique** `student` ID.
- [ ] Tell students to bring `labs/session-01/02-first-vm` **with** `terraform.tfstate` and `terraform.tfvars`, and their ESXi address, user and ID. Anyone who lost the state or the VM will just `terraform apply` in Step 0.
- [ ] Students have `jq` (Labs 2.1 and 2.3). `govc` is optional (Lab 2.4; the Host Client works too). Both are in `lab-setup-guide.md` Part C.
- [ ] Students know their platform: workplace ESXi (everything), free nested ESXi (plan, show, state commands only; apply and destroy fail), no ESXi (watch).
- [ ] Prepare your own **spare VM**: a second folder with a different ID (for example `s99`) that has the end state of Lab 2.1 (size 2 CPU / 1024 MB, note, `shutdown_wait_timeout`). Use it if your live apply fails.
- [ ] Prepare a clean, **working demo folder** with the Session 1 VM already in it, so you can start Step 0 with a real `mv`.
- [ ] Record Lab 2.1 steps 3-4 and Lab 2.4 steps 1-3 as the fallback.

### 30 minutes before

- [ ] Projector works, terminal font is large, notifications are off.
- [ ] Log in to the ESXi Host Client (`https://192.168.100.31/ui`) and keep that tab open on *Virtual Machines*. You will watch the VM power off and on there.
- [ ] vCenter is **off** (check the Host Client). Check free memory on the host.
- [ ] Export the four `VSPHERE_*` variables and the `GOVC_*` variables in your terminal. Run `govc about`.
- [ ] Run the pre-check from Session 1 on your laptop: `bash ../session-01/00-precheck/precheck.sh`. Also run `jq --version`.
- [ ] In your demo folder run `terraform plan` once: `No changes`. Open `solution/main.tf` in a second tab, so you can show the end state.
- [ ] Write the Step 0 commands and the unique-ID rule on the board.
- [ ] Open the slides, the four lab files and this guide side by side.

---

## 3. Run sheet

### 0:00 Move the VM; reading a plan (35 min)

**Goal:** everyone has `vm-lab` running with their Session 1 VM and a plan that says `No changes`. Then they can read every line of a plan and know the symbols (3d).

**Slides for this block:** plan symbols; saved plans. **Lab 2.1 steps 0-2.**

**Suggested budget**

| Minutes | What |
|---|---|
| 10 | Step 0: move state into `vm-lab`, credentials, `init`, `plan` |
| 5 | Step 1: `shutdown_wait_timeout` |
| 3 | Slides: the plan symbols |
| 12 | Step 2: change size, `plan -out`, `show`, `show -json` |
| 5 | Buffer, checkpoint questions |

**Key talking points**
- Welcome back. Today we work in **one folder** all day. The VM from Session 1 comes with us, and the way it comes with us is the state file.
- **Move, don't copy.** `mv` the state; `cp` only `terraform.tfvars`. Two folders with the same state both believe they own the VM. A `destroy` in the old folder would then delete the VM the new folder uses. (If a student asks why: answer in anticipated question 9.)
- If a student changed `main.tf` in Session 1 (memory, a `cdrom` block), they copy **their** `main.tf` over the starting one. Otherwise `plan` wants to undo their Session 1 change.
- Goal of Step 0 is a plan that says `No changes. Your infrastructure matches the configuration.` Everything else is a symptom: see the table below.
- `plan` calls ESXi: it reads the real VM and compares it with state and code. It changes nothing.
- Plan symbols (put the table from Lab 2.1 on the slide): `+` create, `-` destroy, `~` update in place, `-/+` destroy then create the replacement, `+/-` create the replacement first (`create_before_destroy`, Session 4), `<=` read a data source during apply.
- Always read the summary line: `Plan: 0 to add, 1 to change, 0 to destroy.` It is the quickest check before `apply`.
- A line in a plan is a **change in the state of the Terraform world**, not necessarily a call to ESXi. Step 1 shows it: `shutdown_wait_timeout` is `~ update in-place`, but nothing changes on the host.
- Saved plans: `terraform plan -out=tfplan` writes the plan to a file. `terraform show tfplan` prints it back in human form, `terraform show -json tfplan | jq ...` prints it in machine form. This is what CI uses: plan in one job, a human approves, apply the file in the next.
- `tfplan` can contain secrets in plain text. Never commit it. (It is in `.gitignore`.)

**Live demo (Step 0)**

```bash
cd labs/session-02/vm-lab
mv ../../session-01/02-first-vm/terraform.tfstate .
cp ../../session-01/02-first-vm/terraform.tfvars .
export VSPHERE_SERVER="<ESXI_IP>" VSPHERE_USER="root" VSPHERE_PASSWORD='********' VSPHERE_ALLOW_UNVERIFIED_SSL=true
terraform init
terraform plan
```

Tell students: type the password into your own terminal, never onto the projector.

**Live demo (Step 1, Step 2)**

1. Add `shutdown_wait_timeout = 1` and `plan`. Ask the checkpoint question below before applying.
2. `apply`. Quick.
3. Change `num_cpus = 2`, `memory = 1024`. Run:

   ```bash
   terraform plan -out=tfplan
   terraform show tfplan
   terraform show -json tfplan | jq '.resource_changes[] | {address, actions: .change.actions}'
   ```

4. Point out the `~` lines, the summary, the `actions` array (`["update"]`).

**Checkpoint questions**
1. "Step 1: does anything change on the ESXi host when you apply `shutdown_wait_timeout`?" (No. It is a provider setting stored in state only. Not every `~` is an API call to the platform.)
2. "What is the difference between `~` and `-/+`?" (`~` keeps the same object. `-/+` destroys it and creates a new one.)
3. "Why is `tfplan` not committed?" (It may hold secrets in plain text, and it is only valid for one state.)

**Common student problems**

| Problem | Fix |
|---|---|
| `plan` shows `memory = 2048 -> 512` and `- cdrom {...}` | They changed the VM in Session 1 but are using the starting `main.tf`. Copy their Session 1 `main.tf` into `vm-lab`. |
| `plan` shows `+ create` for the VM | No state here (not moved, or they destroyed the VM in Session 1). Move the state, or just `terraform apply` to build a new VM. |
| `Error: ... already exists` on apply | The VM exists but this folder has no state for it. Find the `terraform.tfstate`. If it is lost, delete the VM by hand in the Host Client, then apply. See section 5. |
| Student **copied** the state | Both folders now claim the VM. Delete the state in the old folder now (`rm ../../session-01/02-first-vm/terraform.tfstate*`), then continue. |
| `terraform.tfvars` missing: Terraform prompts for `student` | They forgot the `cp`. |
| `Cannot complete login due to an incorrect user name or password` | Wrong user or password, or the host is in lockdown. See section 5. |
| `x509: certificate signed by unknown authority` | `VSPHERE_ALLOW_UNVERIFIED_SSL` is not set in this shell. |
| `jq: command not found` | Install it (`lab-setup-guide.md` Part C) or skip the jq line. |
| `datastore '...' not found` | The workplace host uses another datastore name. Set `datastore` and `network` in `terraform.tfvars`. |

**Timing tip:** Step 0 is where classes lose time. Do not let it pass 15 minutes. A student who still has no working state at 0:15 runs `terraform apply` (new VM) and carries on; the VM is theirs for the rest of the day anyway. Skip the `show -json` line for anyone without `jq`. It is repeated in Lab 2.3.

---

### 0:35 Apply: in-place vs replacement (35 min)

**Goal:** students apply a saved plan, see that "in-place" is not "no downtime", and force a replacement with `-replace` (3e).

**Slides for this block:** in-place vs replace (what makes an update in place vs a replacement). **Lab 2.1 steps 3-5.**

**Suggested budget**

| Minutes | What |
|---|---|
| 5 | Slides: in-place vs replace, `-replace` |
| 10 | Step 3: `apply tfplan`, watch the Host Client, stale plan |
| 15 | Step 4: note `moid`, `plan -replace`, apply, new `moid` |
| 5 | Step 5: annotation (cut first) |

**Key talking points**
- **In place (`~`):** the provider updates the same object: same `moid`, same UUID. **Replacement (`-/+`):** destroy and create: a new object, and everything inside the old disk is gone.
- **In place does not mean "no downtime".** Changing CPU or memory on a VM without hot-add means the VM is powered off, changed and powered on. Watch the Host Client during the apply.
- Terraform first asks the guest OS to shut down and waits `shutdown_wait_timeout` (default 3 minutes). Our VMs have no OS and no VMware Tools, so nobody answers and the wait is wasted. That is why we set it to 1 minute. After the wait, Terraform powers the VM off.
- **Timing is unverified** (see the note at the top). Expect somewhere between a few seconds and about a minute at `Still modifying...`, then a power-off, the change, and a power-on. Use the number from `smoke.sh`. While it runs, keep talking: ask the checkpoint question.
- `terraform apply tfplan` has **no `yes` prompt**. You already reviewed exactly this plan. That is the point of saved plans (see anticipated question 3).
- The saved plan is **tied to the state it was made from**. Run it again and you get `Error: Saved plan is stale`. A saved plan cannot be reused.
- Replacement: sometimes the object is broken in a way Terraform cannot see (a corrupt disk, a stuck guest). `terraform apply -replace="vsphere_virtual_machine.vm"` tells Terraform: treat this one as needing replacement. `plan -replace=...` shows it first, with `# ... will be replaced, as requested`.
- `terraform taint` did this in older versions. It is **deprecated**; `-replace` is the exam answer. Why `-replace` is better: it is part of a normal plan, so you see it and can save it, while `taint` edits the state before anyone has reviewed anything.
- After the replacement, `terraform output vm_moid` has a new value. Same name, new VM.

**Live demo**

```bash
terraform apply tfplan                 # no prompt; watch the Host Client
terraform apply tfplan                 # Error: Saved plan is stale
terraform output vm_moid
terraform plan -replace="vsphere_virtual_machine.vm"
terraform apply -replace="vsphere_virtual_machine.vm"
terraform output vm_moid               # different
```

Then Step 5: add `annotation = "Managed by Terraform. Owner: sNN"`. Apply: the VM stays running. Say "this one is a change without a power cycle". Lab 2.4 uses this field.

**Checkpoint questions**
1. "The plan said update in-place. Was there downtime?" (Yes. In-place means the same object, not that nothing happens to it.)
2. "Why did `terraform apply tfplan` not ask for `yes`?" (The plan was already reviewed. A saved plan is applied as is.)
3. "What changed after `-replace`?" (`moid` and `uuid`: a new VM. The old disk is gone.)
4. "What do you use instead of `terraform taint`?" (`-replace`.)

**Common student problems**

| Problem | Fix |
|---|---|
| Apply waits about 1 minute at `Still modifying...` | Normal. It waits `shutdown_wait_timeout`, then powers off. Say so before it happens. |
| Apply seems stuck much longer than that | See section 5, "Stuck at Still modifying". |
| `Error: Saved plan is stale` on the **first** apply | They changed code or state after `plan -out` (another apply, or a `plan -refresh-only` apply). Run `plan -out=tfplan` again. |
| `Error: Saved plan is stale` on the second apply | Expected. This is what Step 3 wants them to see. |
| Power-on fails: `insufficient memory` | The host is out of RAM. Use `memory = 1024` or less; see section 5. |
| Student ran plain `terraform apply` instead of `apply tfplan` | Fine. It shows a new plan and asks for `yes`. The lesson is the prompt difference. |
| `plan -replace` shows `No changes` | Quote the address and use the exact name: `vsphere_virtual_machine.vm`. |

**Timing tip:** if behind, cut Step 5 first (annotation). Lab 2.4 needs the annotation, so tell students to add it at the start of 3:00 (Lab 2.4 says so). Do not cut the stale-plan demo or `-replace`: both are tested.

---

### 1:10 Destroy (20 min)

**Goal:** students remove one resource by deleting its code, see why `-target` leaves code and reality out of sync, and destroy and rebuild the whole lab (3f).

**Slides for this block:** none. Teach from the lab, five minutes per step. **Lab 2.2.**

**Suggested budget**

| Minutes | What |
|---|---|
| 5 | Step 1: add `test` VM, apply |
| 5 | Step 2: delete its code, `plan`, put it back |
| 5 | Step 3: `-target` |
| 5 | Step 4: `plan -destroy`, `destroy`, rebuild |

**Key talking points**
- Terraform is declarative. **The normal way to remove something is to delete its code.** `plan` then says `# ... will be destroyed (because ... is not in configuration)`.
- `terraform plan -destroy` is a **preview** of a full destroy. It changes nothing. `terraform destroy` is the same as `terraform apply -destroy`: same plan, same prompt.
- `-target` limits plan, apply or destroy to one resource (and what it depends on). Terraform prints a warning: `Resource targeting is in effect ... not for routine use`. It is for emergencies: a broken resource blocking everything else, or recovering from an error.
- After `terraform destroy -target=...`, the VM is gone, but the **code still declares it**. The next `plan` says `1 to add`: code and reality disagree. That is the lesson. The right way is Step 2.
- Destroy order follows the dependency graph **backwards**. (Session 1: the VM was destroyed before its folder. Here the VMs do not depend on each other, so order does not matter. The data sources have nothing to destroy.)
- After a full `destroy`, the state file still exists but holds no resources (`terraform state list` prints nothing). We rebuild with `apply` because the next labs need a VM.

**Live demo:** follow the four steps in order. In Step 2, **do not apply the deletion**. Put the block back and show `No changes`; students are often surprised that `plan` shows a destroy and nothing happens.

**Checkpoint questions**
1. "After `destroy -target=...test`, what does `plan` say, and why?" (`1 to add`. The code still declares the `test` VM.)
2. "How do you preview a destroy?" (`terraform plan -destroy`.)
3. "How do you normally remove one VM?" (Delete its resource block, then plan and apply.)
4. "After the full destroy, does `terraform.tfstate` still exist?" (Yes, with no resources.)

**Common student problems**

| Problem | Fix |
|---|---|
| `Plan: 1 to add` after Step 3 and they cannot see why | The `test` block is still in `main.tf`. That is the point; then delete the block. |
| They deleted the `test` block **and** ran `apply` in Step 2 | The `test` VM is already gone, so Step 3's `destroy -target` has nothing to do. Do Step 3 as a demo only, or add the block and apply again. |
| `Error: ... already exists` for `test01` | Another student has the same ID, or the VM was left by an earlier try. Delete it by hand in the Host Client or have the admin run `govc vm.destroy`. |
| Free ESXi student: `apply` fails with a licence error | Expected. They watch Steps 1 and 3-4 and do Step 2 (plan only). See section 5. |
| Typed `yes` too early and destroyed more than expected | `destroy` removes everything in **this folder's state** only. Rebuild with `apply`. |

**Timing tip:** this block is tight (20 minutes for four applies or destroys). Run Step 1 as a demo for the whole class while students type it in, and finish Step 4 after the break if needed. Never skip the `-target` warning: the exam asks about it.

---

### 1:30 Break (15 min)

- Start the clock visibly. Return time on the screen.
- During the break: check that every student has a VM and `plan` says `No changes` (rebuild after Step 4 is done). Help anyone who is behind with Step 0 or the rebuild.
- Free ESXi students: nothing to rebuild. They will still do Lab 2.3.
- Instructor: `cd vm-lab`, have a **freshly rebuilt VM** and open slides for the state talk.

---

### 1:45 How Terraform uses state; the local backend (30 min)

**Goal:** students can explain why state exists (mapping, metadata, performance), where it lives by default (local backend, `terraform.tfstate`), and what must never happen to it (2d, 6a).

**Slides for this block:** state. No lab in this block, but keep a terminal open on `vm-lab` and look at the real file during the talk. **Lab 2.3 step 1** is the first thing after the talk.

**Suggested budget**

| Minutes | What |
|---|---|
| 5 | Why state: the mapping problem |
| 5 | Metadata and dependencies; performance |
| 5 | The local backend, `terraform.tfstate`, `.backup` |
| 5 | `serial`, `lineage` |
| 5 | Secrets in state; never edit, never commit |
| 3 | Preview: remote backends (Session 6) |
| 2 | Questions |

**Key talking points**

1. **Mapping.** Your code says `resource "vsphere_virtual_machine" "vm"`. The platform has a VM with a `moid`. Something has to remember that the first is the second. That is the state. Without it Terraform cannot tell "create" from "update".
   - Show it live: `terraform state show vsphere_virtual_machine.vm | head`. Find the `moid`.
   - Ask: "You delete `terraform.tfstate`. What does the next `plan` say?" (`1 to add`. The real VM is orphaned: still running, unmanaged. Apply fails with "already exists".)
2. **Metadata and dependencies.** State also stores the dependencies of each resource and some provider metadata. This is how Terraform knows the destroy order, even for a resource you already removed from the code (the code no longer says what it depended on; the state does).
3. **Performance.** State caches the attributes of every resource. A plan can compare against the state instead of listing everything on the platform. For very large setups this matters; there are flags such as `-refresh=false` (do not teach them today).
   - Reality check for honesty: by default, `plan` and `apply` **still refresh** each resource it manages (one API read per object). The state is the starting point, not a replacement for reading. That is what drift detection in Lab 2.4 uses.
4. **The local backend is the default.** If your configuration has no `backend` block, Terraform uses the **local** backend: a file called `terraform.tfstate` in the working directory. Say the exact file name: it is an exam question.
5. **`terraform.tfstate.backup`.** Before Terraform writes a changed state, the previous version is saved as `terraform.tfstate.backup` (one version only: the one before the last write). It is not a backup strategy; it is a "one step back" for emergencies.
6. **`serial` and `lineage`.**
   - `serial` is a counter that goes up each time the state is written. It says which copy is newer.
   - `lineage` is a random ID given when the state was first created. Two states with different lineages are different histories, not different versions of one thing.
   - They exist so Terraform and the backends can refuse to overwrite a newer state with an older one, or one history with another (anticipated question 12).
7. **Secrets in state.** State is plain JSON. It can hold passwords, keys, tokens: any attribute value, including those marked `sensitive`. `sensitive = true` only hides values in the CLI output; the state still has them. So: protect the state like a secret.
8. **Never edit by hand. Never commit.** The format is not a contract; one wrong comma and Terraform fails to read it. If you need to change state, use `terraform state ...` commands (Session 6), and take a copy first. Do not put `terraform.tfstate` in git: it holds secrets and two people committing it will overwrite each other.
9. **Preview: remote backends (Session 6).** One local file is fine for one person. For a team it fails: no sharing, no locking, no history. Session 6 moves state to a remote backend (for example S3) with locking. Tell them only: "A team needs a shared, locked, encrypted state. That comes in Session 6." Do not explain backend blocks today.

**Live demo:** during the talk, with the terminal open:

```bash
ls -l terraform.tfstate terraform.tfstate.backup
head -c 600 terraform.tfstate
```

Show the real file. Keep it short; Lab 2.3 goes through it field by field.

**Checkpoint questions**
1. "Name the three purposes of state." (Mapping, metadata/dependencies, performance.)
2. "What is the default backend and the file name?" (Local; `terraform.tfstate` in the working directory.)
3. "Why is `terraform.tfstate` not committed to git?" (It can contain secrets in plain text. Teams use a remote backend.)
4. "What is `terraform.tfstate.backup`?" (The state as it was before the last write.)

**Common student problems**
- "Is `.terraform/` the state?" No. `.terraform/` holds providers and backend settings. The state is `terraform.tfstate`.
- "Is the state the same as the real world?" No. It is Terraform's **record** of it, as of the last run. Drift is the gap (Lab 2.4).
- "If `sensitive` hides it, is it safe?" No. It only hides it in the CLI.

**Timing tip:** if you are behind, cut performance (point 3) to one sentence and skip the `serial`/`lineage` detail until Lab 2.3 step 1, where students see the fields. Do not skip secrets, "never edit/commit" or the local backend file name.

---

### 2:15 Lab 2.3: look inside the state (45 min)

**Goal:** students read the state file and inspect it with `state list`, `state show`, `show`, `show -json` and `output` (7b).

**Slides for this block:** none. **Lab 2.3.**

**Suggested budget**

| Minutes | What |
|---|---|
| 10 | Step 1: the state file is JSON; `serial`, `lineage`; five entries |
| 10 | Step 2: `state list`, `state show` |
| 15 | Step 3: `show`, `show -json`, jq |
| 5 | Step 4: outputs come from state |
| 5 | Step 5: why state (discussion, uses the 1:45 talk) |

**Key talking points**
- **Step 1.** `jq '{version, terraform_version, serial, lineage}' terraform.tfstate`. Point at `serial` and `lineage`. Ask the five-entries question: one `managed` resource and four `data` sources. **Data sources are in the state too**, with the values they read last time.
- **Step 2.** `terraform state list` prints addresses (`vsphere_virtual_machine.vm`, `data.vsphere_datastore.ds`). `terraform state show <address>` prints every attribute Terraform knows about **one** object, including values you never wrote (`moid`, `uuid`, `power_state`). `state show` reads the state; it does not call ESXi.
- Find the datastore's `stats`: free and total capacity. Useful for the "do we have room" discussion.
- **Step 3.** `terraform show` (no argument) prints the **whole state** in human form. `terraform show tfplan` prints a **saved plan** (Lab 2.1). `-json` gives the machine-readable form. This is the stable interface: scripts read `show -json`, not the raw file, because the raw file layout can change between versions.
  - Difference to remember: `state show <addr>` = one object, human only. `show` = everything, human or JSON.
- **Step 4.** `terraform output` reads the **saved output values from state**. Break the password (`export VSPHERE_PASSWORD=wrong`): `output` still works; `plan` fails at login. Then put it back. Very effective: it shows that the state is a local file and `output` never talks to ESXi.
- **Step 5.** Use the table (mapping, metadata, performance) as the recap of the talk.

**Live demo:** follow the lab; show `jq` first, then the Terraform commands. If a student has no `jq`, they use `terraform state show` and `terraform show`.

**Checkpoint questions**
1. "Why five entries for one VM?" (One resource, four data sources.)
2. "What does `terraform output` need to work?" (Only the state. No ESXi connection.)
3. "Difference between `state show` and `show -json`?" (`state show`: one address, human text. `show -json`: the whole state, machine-readable.)
4. "What changes `serial`?" (Every write to the state.)
5. "You delete `terraform.tfstate`. What does `plan` say?" (`1 to add`; the VM is orphaned.)

**Common student problems**

| Problem | Fix |
|---|---|
| `jq: command not found` | Install jq, or skip the jq lines and use the Terraform commands. |
| `terraform state show` says `No instance found for the given address` | Wrong or missing address. Run `terraform state list` and copy it. Data sources need the `data.` prefix. |
| `state show` needs quotes in Windows PowerShell | Quote the address: `terraform state show "vsphere_virtual_machine.vm"`. |
| `terraform output vm_moid` prints a quoted string | Use `-raw` for a bare value. |
| They set a wrong password and forgot to put it back | `plan` fails at login. `export VSPHERE_PASSWORD='...'` again. |
| `terraform.tfstate.backup` is missing | Nothing wrote the state since the file was created (for example a fresh `apply` of a new VM). It appears after the next change. |
| Free ESXi student: no state because `apply` failed | They use the instructor's screen share, or a state saved from a demo. Steps 1-5 only read, so they can follow with the demo output. |

**Timing tip:** if behind, cut Step 4's wrong-password experiment to a demo, and run Step 5 as discussion only. Do not cut `state list`, `state show` and `show -json`: they are the exam content for 7b.

---

### 3:00 Lab 2.4: drift (25 min)

**Goal:** students cause drift, see how `plan` reports it, update state with `-refresh-only`, and ignore an attribute on purpose (6d).

**Slides for this block:** none. **Lab 2.4.** Students who skipped Lab 2.1 step 5 add the annotation and apply first (2 minutes).

**Suggested budget**

| Minutes | What |
|---|---|
| 5 | Step 1: change the note by hand (Host Client or `govc`) |
| 5 | Step 2: `plan` shows drift and the plan to undo it |
| 5 | Step 3: `plan -refresh-only`, `apply -refresh-only`, plan again |
| 5 | Step 4: `ignore_changes` |
| 5 | Step 5: clean up; decide keep or destroy |

**Key talking points**
- **Drift:** the real object differs from what Terraform last recorded. Someone clicked in the Host Client; a backup tool set a note; an auto-scaler changed a size.
- `terraform plan` **refreshes first** (reads every managed object). If anything changed outside Terraform it prints `Note: Objects have changed outside of Terraform`, shows the old and new values, and then plans to put things back to what the code says.
- **`-refresh-only`** is the "accept reality" mode: `plan -refresh-only` shows only the drift; `apply -refresh-only` writes it into the **state**. It never changes the VM.
- After that, a normal `plan` still wants to change the note back, because the **code** has not changed. To keep a hand change, change the code too (or ignore the attribute).
- **`terraform refresh`** is the old command for this. It is **deprecated**, because it writes the state **without showing you the changes first**. Use `apply -refresh-only`.
- **`lifecycle { ignore_changes = [annotation] }`**: Terraform still reads the note but never tries to correct it. Good for attributes that people or other tools own on purpose. Risk: you stop seeing real drift on that attribute, and it is easy to hide a problem. Use it narrowly (anticipated question 14).
- Cleanup: **keep the VM** for Session 3, unless the host needs the RAM.

**Live demo**

1. `govc vm.change -vm sNN-vm01 -annotation "Changed by hand"` (or edit the note in the Host Client). If the `govc` flag fails, use the Host Client and move on: `smoke.sh` tells you before the day whether it works.
2. `terraform plan`, read the `Note:` block aloud.
3. `plan -refresh-only`, `apply -refresh-only`, `plan` again. Ask the checkpoint question.
4. Add `ignore_changes`, `plan` → `No changes`. Change the note again: still `No changes`.

**Checkpoint questions**
1. "After `apply -refresh-only`, why does `plan` still want to change the note?" (The code did not change. `-refresh-only` updates the state.)
2. "What does `apply -refresh-only` change on the VM?" (Nothing.)
3. "Why is `terraform refresh` deprecated?" (It writes state without a review step.)
4. "What is the risk of `ignore_changes`?" (You stop seeing drift on that attribute.)

**Common student problems**

| Problem | Fix |
|---|---|
| `plan` shows no drift | The note was changed on another VM or not saved. Check the VM name. Also: they skipped Lab 2.1 step 5, so there is no annotation in code and state. |
| `govc: vm 'sNN-vm01' not found` | `GOVC_URL`, `GOVC_USERNAME`, `GOVC_PASSWORD` and `GOVC_INSECURE` are not set in this shell, or the VM name is wrong. |
| `govc vm.change` flag error | Check `govc vm.change -h`. Use the Host Client instead. |
| Host Client: cannot find *Notes* | Menu names differ by ESXi version. *Edit settings > VM Options > General Options > Notes* in 7 and 8. Use `govc` otherwise. |
| `Unsupported attribute` for `ignore_changes` | `lifecycle` must be **inside** the resource block; list the attribute names without quotes. |
| After `ignore_changes`, plan still shows drift | The `lifecycle` block is inside the `test` block (an old copy) or in the wrong resource. |

**Timing tip:** if behind, do Steps 1-3 as a demo and let students finish Step 4 as homework. If `govc` is a problem, the Host Client works (lab Step 1 gives both). Do not skip Step 3's checkpoint: it is tested ("what does refresh-only change").

---

### 3:25 Recap and quiz (5 min)

**Goal:** lock in the exam objectives and hand over to Session 3.

**Slides for this block:** recap.

**Suggested budget:** 3 min recap, 2 min handover (section 6). The quiz has 8 questions and takes about 10 minutes. Run Q1, Q2, Q5 and Q8 in class, and hand out the rest as homework.

**Key talking points (recap)**
- `plan` shows `+ - ~ -/+`. `plan -out` saves a plan; `apply tfplan` applies it without a prompt, only while the state still matches.
- In place is the same object; replacement is a new one. `-replace` replaces `taint`.
- `plan -destroy` previews a destroy. `-target` is for emergencies; delete the code instead.
- State is the mapping from code to real objects, plus metadata and performance. Default: local backend, `terraform.tfstate`. It can hold secrets. Never edit or commit it.
- `state list`, `state show`, `show`, `show -json`, `output` read the state.
- Drift: `plan` shows it, `-refresh-only` records it in state, `ignore_changes` hides it on purpose.

**Quiz:** [`quiz.md`](quiz.md) has 8 questions and a collapsible answer key. Mapping to objectives and the correct answers:

| Q | Obj | Topic | Answer |
|---|---|---|---|
| 1 | 3d | Meaning of `-/+` | C |
| 2 | 3d, 3e | Saved plan applied without a prompt (choose two) | B and D |
| 3 | 3e | Replace a broken resource without changing code | A |
| 4 | 3f | Preview a full destroy | D |
| 5 | 3f | `-target` (choose two) | A and C |
| 6 | 2d, 6a | Where state lives when no backend is configured | B |
| 7 | 7b | `state list`, `show -json`, data sources (choose two) | B and D |
| 8 | 6d | Accept an out-of-band change into state without touching the VM | C |

**Common student problems**
- Q2: students think the saved plan is re-planned on apply. It is not: it is applied as saved, and rejected if stale.
- Q4: students pick `terraform destroy` (it prompts, but it also destroys when confirmed). The question asks for a preview.
- Q7: students think `state list` calls ESXi. It reads the state.

**Timing tip:** if short on time, run Q2 and Q8 only and send the rest. Never skip the handover.

---

## 4. Anticipated questions

1. **What is the difference between `~` and `-/+`?**
   `~` is an update in place: the provider changes the same object (same `moid`). `-/+` is a replacement: destroy the old object and create a new one (a new `moid`). Terraform replaces when an argument cannot be changed on a live object; the plan marks the line `# forces replacement`. `+/-` is also a replacement, but with `create_before_destroy` (Session 4).

2. **Does "in-place" mean no downtime?**
   No. It only means the object is kept. In our lab the VM is powered off for the CPU and memory change, because hot-add is off, and powered on again. Whether an in-place update interrupts the service depends on the provider and the attribute. Read the provider docs for the attribute.

3. **Why does `terraform apply tfplan` not ask for confirmation?**
   You approved the plan when you reviewed it. The file holds the exact actions, so there is nothing new to confirm. Applying a saved plan is the pipeline pattern: one step plans and stores the file, a person approves, a later step applies the file. If the state changed in between, apply refuses with `Saved plan is stale`.

4. **`-target` or removing the code?**
   Removing the code. The code is the source of truth; the next plan from the same code must give the result you want. `-target` changes the infrastructure but leaves the code as it was, so the next plan wants to create it again. Use `-target` only for emergencies (recovery from a failed apply, a broken resource blocking the rest). Terraform warns you each time.

5. **What happened to `terraform taint`?**
   Deprecated since 0.15.2. Use `terraform apply -replace="<address>"`. Reason: `-replace` is part of a normal plan, so you see it, can review it, and can save it. `taint` edits the state first. (`terraform untaint` is also deprecated, because with `-replace` there is nothing to untaint.)

6. **What happened to `terraform refresh`?**
   Deprecated. It is `apply -refresh-only -auto-approve`: it updates state from reality **without showing you what changed**. Use `plan -refresh-only` to look and `apply -refresh-only` to accept.

7. **Why are data sources in the state?**
   Terraform records the values a data source read, along with other resources, so it can use them in the graph and show what changed between runs. They are read again at every plan. A data source in the state is not something Terraform manages: removing it from the state would not delete anything on the platform.

8. **Can I edit the state?**
   Not by hand. The file is plain JSON, but you can break it or lose the match with reality. Use the CLI instead (`terraform state mv`, `rm`, `import`; Session 6). If you must touch it, copy the file first and work on a stopped system. Never commit it.

9. **What if two people share one state?**
   With a local file, they each have their own copy. Both think they own the VM. Each `apply` changes the real VM and records it in one copy only, so the copies drift apart, and a `destroy` in one folder deletes what the other uses. That is why we `mv` the state in Step 0, not `cp`. The real fix is a remote backend with locking (Session 6).

10. **`terraform show` vs `terraform state show`?**
    `show` with no argument prints the whole state; with a plan file it prints that plan; `-json` gives machine-readable output. `state show <address>` prints one object, in human form only. Both read from the state or file, not from ESXi.

11. **Why does `terraform output` work with a wrong password?**
    It reads the output values saved in state at the last apply. It never calls the provider. `plan` and `apply` do call it, so they fail at login.

12. **What does `lineage` protect against?**
    Mixing up two different state histories. `lineage` is set when a state is first created and does not change. If you try to overwrite a state with one that has a different lineage, Terraform and its backends refuse (for example `terraform state push` complains and needs `-force`). `serial` protects against overwriting a newer state with an older one. They do **not** protect against two people writing at the same time; that is locking (Session 6).

13. **Is a state backup the same as `terraform.tfstate.backup`?**
    No. That file is only the previous version. A real backup is a copy somewhere else (remote backend with versioning, Session 6).

14. **What are the risks of `ignore_changes`?**
    It hides drift: Terraform still reads the attribute but never reports or fixes it. A real problem on that attribute goes unseen. Use it only for attributes that someone else owns on purpose (notes, tags set by a tool), list the attributes one by one, and avoid `ignore_changes = all`.

15. **What does `apply -refresh-only` do to the VM?**
    Nothing. It updates the state to match what ESXi reports. To change the VM, the code must change and a normal `apply` must run.

16. **Can I use `plan -destroy` and then apply the plan?**
    Yes: `terraform plan -destroy -out=destroy.tfplan`, review, `terraform apply destroy.tfplan`. This is how pipelines gate a destroy.

---

## 5. If things break

### Stuck at `Still modifying...` (CPU/RAM change)

- **Expected:** with `shutdown_wait_timeout = 1`, the apply waits for the guest to shut down for up to 1 minute (there is no guest OS to answer), then powers the VM off, changes it, and powers it on. **The real duration on your host is not verified.** Use the number from `smoke.sh`.
- **If it waits longer** (several minutes): Terraform is probably waiting for the default 3 minutes because the student did not save `shutdown_wait_timeout = 1`, or applied before saving. Let it finish: do not press Ctrl+C. Next time check `terraform plan` shows no `shutdown_wait_timeout` change.
- **If it seems stuck for good:** look at the Host Client: *Monitor > Tasks* for the host or the VM, and the VM's power state. If the task failed, the error is shown; common causes are insufficient memory (next section) and a VM locked by another operation.
- **After an interrupted apply:** run `terraform plan`. The state is usually correct (Terraform saves state as it goes), and plan shows what is left. If the VM is half-changed, `terraform apply` finishes it. Do not delete the VM by hand.
- **If it works in demo but not for students:** check that their user role can **reconfigure** VMs and power them on and off, not only create them.

### Stale plan

- `Error: Saved plan is stale` means the state changed after `plan -out`. In the lab, this is expected on the **second** `apply tfplan`.
- If it appears on the first one: another apply, a `-refresh-only` apply, or a manual state command ran in between. Run `terraform plan -out=tfplan` again.

### VM already exists, or the state is lost

- `Error: ... already exists` on apply: Terraform has no state for a VM with that name. Causes: the state was not moved (Step 0), was deleted, or belongs to another folder.
- Fix in order:
  1. Look for `terraform.tfstate` in `labs/session-01/02-first-vm` (and any `copy` folder). If found, `mv` it into `vm-lab`.
  2. If it is really lost: delete the VM (Host Client, or `govc vm.destroy sNN-vm01`; check the name with `govc find / -type m`) and run `terraform apply`. The new VM replaces the old one.
  3. Importing the old VM is a Session 6 topic. Do not teach it here.
- A student who **copied** the state: the old folder still has a state. Delete the old copy, or the next `destroy` in the old folder removes the VM.

### Out of memory

- **Student host:** each student needs up to 1.25 GB of RAM at once (1 GB VM plus the 256 MB `test` VM in Lab 2.2). On a shared workplace host, check free RAM before class (`lab-setup-guide.md` Part B). Destroying the `test` VM at the end of Lab 2.2 frees 256 MB.
- **Symptom:** the resize or `apply` fails at power-on with `insufficient memory`.
- **Fix:** power off or destroy other lab VMs; use `memory = 512` for the main VM (the plan still shows a change). Run `terraform apply` again: Terraform retries the power-on and does not create a second VM.
- **Your demo server (16 GB):** keep vCenter **off** for the whole session. It takes about 14 GB and leaves almost nothing for VMs. If you accidentally left it on, power it off in the Host Client before 0:00.

### Lockdown mode or login errors

- `Cannot complete login due to an incorrect user name or password` on `plan` or `apply`: wrong user or password, or the host is in **lockdown mode** under a vCenter.
- Check the credentials with `govc about` (set the `GOVC_*` variables).
- If the host is in lockdown: either disable lockdown on the host (host > *Configure > Security Profile > Lockdown Mode*; ⚠ verify on your build), or point `VSPHERE_SERVER` at the vCenter and set `datacenter` and `host` in `terraform.tfvars` (see `terraform.tfvars.example`). The vCenter path is **not verified** with the `null` defaults; run `smoke.sh` against it if you plan to use it. If you use vCenter, the `moid` values look like `vm-1042`; state and labs work the same.
- A student who moves from ESXi to vCenter has a different state (the VM is a different object). They must start from a clean `apply` in `vm-lab`.

### Licence error: free ESXi

- `current license or ESXi version prohibits execution of the requested operation` at `apply` or `destroy`: the free licence makes the API read-only. See Session 1 (2:25 block).
- What works for these students: `init`, `validate`, `plan`, `show`, and the state commands (they need an existing state: give them one from your demo, or they follow your screen). What fails: `apply`, `apply tfplan`, `-replace`, `destroy`.
- Give them a role in the class: they read the plan and predict the result before you apply on the projector.
- If the **workplace** host shows this error, the licence is free or expired: `govc license.ls`. Fix before class.

### jq missing

- Only the `jq` lines in Labs 2.1 and 2.3 need it. Student alternatives: use `terraform show tfplan` and `terraform state show`; or install jq (`lab-setup-guide.md` Part C).
- Windows: `winget install jqlang.jq`, then open a **new** terminal.

### `smoke.sh` problems (instructor)

- Needs `terraform`, `jq`, `govc` on `PATH` and the four `VSPHERE_*` variables. Without the `govc` step, you only miss the Lab 2.4 check.
- It uses throwaway names `zz99-vm01` and `zz99-test01`. If it fails halfway, clean up with `govc vm.destroy zz99-vm01` and `govc vm.destroy zz99-test01` (`lab-setup-guide.md` Part E).
- It uses a temporary folder, not your `vm-lab`. It does not touch your state.

---

## 6. Handover to Session 3

**Students keep `vm-lab` and its state.** At the end of Lab 2.4 they have one VM (`<student>-vm01`) managed from `labs/session-02/vm-lab`, with `ignore_changes = [annotation]` in the code and a state file that matches. Session 3 continues from this folder. The `test` VM was removed in Lab 2.2.

**Say before closing**
- Do not delete `vm-lab` or `terraform.tfstate` in it. They are the link between code and VM.
- Do not rename or delete the VM in the Host Client.
- Do not commit `terraform.tfstate*`, `terraform.tfvars`, `tfplan` or `.terraform/`. The lab `.gitignore` already covers them.
- Keep the same laptop and the same Terraform version if possible.
- If the host needs the RAM: run `terraform destroy` in `vm-lab`. Next session starts with `terraform apply`. (Decide before class which of the two you ask for.)

**Student check before leaving** (each student shows you, or does it quickly):

```bash
cd labs/session-02/vm-lab
terraform state list             # vsphere_virtual_machine.vm and four data sources
terraform plan                   # No changes. Your infrastructure matches the configuration.
```

- `terraform state list` shows the VM and four `data.` entries (or nothing, if the student ran `destroy` on purpose).
- `terraform plan` says `No changes`. If it shows the note changing back, the `ignore_changes` block is missing or in the wrong place.
- `main.tf` matches [`solution/main.tf`](solution/main.tf) (the `test` block is gone).
- The VM `<student>-vm01` is visible in the Host Client.

**Instructor tasks after the session**
- [ ] Note which students did not finish, and schedule catch-up before Session 3.
- [ ] Update this guide with the real timing of the CPU/RAM change, and fix the `govc vm.change` and vCenter notes, from what `smoke.sh` and the class showed.
- [ ] Check that no `*-test01` VM is left on the workplace host (`lab-setup-guide.md` Part E), and that no student ended with a half-changed VM.
- [ ] If the host is short on RAM, ask students to run `terraform destroy`, or have the admin run `govc vm.destroy` (students then run `terraform apply` next time; their state will be out of date, so `terraform apply` shows a plan to create).
- [ ] Share the quiz answers and the homework (the rest of `quiz.md`, Lab 2.4 step 4 for anyone who did not finish).
- [ ] Confirm the date for Session 3.

**One-line preview for the class:** "Next time we stop hard-coding values in `main.tf`: variables, types and expressions."
