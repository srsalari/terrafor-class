# Session 2 lab setup guide (vSphere)

For the instructor and for the admin of the team's ESXi host. This guide prepares what Labs 2.1 to 2.4 (`vm-lab`) and the checklist in [`README.md`](README.md) assume: your demo ESXi host, the workplace ESXi host that students share, student laptops, moving the Session 1 state, and cleanup. Session 1 setup ([`../session-01/lab-setup-guide.md`](../session-01/lab-setup-guide.md)) still applies; this guide only adds what is new.

Every step has a command or a click path, and a **Verify:** line. Names match the lab files (`datastore1`, `VM Network`, VM names `sNN-vm01` and `sNN-test01`). If your environment differs, students change the values in `terraform.tfvars`.

> **Convention.** `sNN` means `s01`, `s02`, ... zero-padded to two digits. Anything marked **⚠ Verify on your build** depends on the vSphere or tool version and must be checked on your own system before class.
>
> **govc.** The commands below use only these subcommands: `about`, `ls`, `find`, `license.ls`, `vm.info`, `vm.destroy`, `vm.change`. For anything else the text says "check `govc <cmd> -h`". Run `govc <cmd> -h` before relying on it.

---

## Overview

Students are online and run Terraform **from their own laptops**, straight to the team's ESXi host at their workplace. No vCenter is needed. VMs have no OS: no VMware Tools, no IP address, no DHCP or SSH.

| Platform | Who | What works |
|---|---|---|
| **Workplace ESXi** (licensed, shared by the team) | Students with an ESXi user on it | Everything: `plan`, `apply`, `-replace`, `destroy`, state commands, drift |
| **Instructor ESXi** (HP server, 16 GB RAM, licensed ESXi 8 at `192.168.100.31`) | Instructor only (demo) | Everything. vCenter (14 GB) stays **off** in Session 2 |
| **Workplace host under vCenter, lockdown mode** | Students whose host rejects direct logins | Same as workplace ESXi, but `VSPHERE_SERVER` is the vCenter and `datacenter` and `host` are set in `terraform.tfvars` |
| **Free ESXi**, nested | Students with their own nested host | `plan`, `show` and the state commands. `apply` and `destroy` fail with `current license or ESXi version prohibits execution of the requested operation`. They follow the demo for those steps |
| **No ESXi** | Students without a host | They watch the demo and read plans |

Resources per student, at most two small VMs at once: `sNN-vm01` (up to 2 vCPU, 1 GB RAM after the resize, thin 8 GB disk) and, only in Lab 2.2, `sNN-test01` (1 vCPU, 256 MB, thin 1 GB disk).

---

## Part A: Instructor demo host

### A.1 Connect, then check the licence

Connect as in Session 1 (A.1): a `~/.govc-esxi.env` with `GOVC_URL`, `GOVC_USERNAME`, `GOVC_PASSWORD` and `GOVC_INSECURE=1`, then `source ~/.govc-esxi.env`.

```bash
govc about
govc license.ls
```

**Verify:** `govc about` prints `API type: HostAgent`. `govc license.ls` lists a real licence key: not an expired evaluation and not the free "VMware vSphere Hypervisor" licence. Session 2 needs write access on the demo host (apply, destroy), so a free licence fails the labs.

### A.2 Free RAM: vCenter off

The demo VM needs up to 1 GB, the `test` VM 256 MB. The 16 GB server cannot hold those next to vCenter (about 14 GB).

1. In the Host Client, *Virtual Machines*: if the vCenter VM is on, power it off (right click > *Power > Power off*, or shut it down from its own console).
2. Look at the *Host* page for free memory.

**Verify:** `govc vm.info <vcenter-vm-name>` shows `Power state: poweredOff` (find the name with `govc find / -type m`), and the Host Client shows at least 2 GB free. For the full host report check `govc host.info -h`.

### A.3 Run `smoke.sh`

`smoke.sh` runs every risky step of Labs 2.1 to 2.4 against your host, in a temporary copy of `vm-lab`, with VMs named `zz99-vm01` and `zz99-test01`, then destroys them. Not verified on real hardware yet: **this is where you verify it.**

Needs `terraform`, `jq` and `govc` on `PATH` (Part C), and:

```bash
export VSPHERE_SERVER="192.168.100.31" VSPHERE_USER="root" VSPHERE_PASSWORD='********' VSPHERE_ALLOW_UNVERIFIED_SSL=true
cd labs/session-02
bash smoke.sh 2>&1 | tee ~/smoke-session2.log
```

Expected output, section by section (the script prints a header per step: `=== ...`):

| Section | Expected |
|---|---|
| init + apply | `init ok`, `Apply complete! Resources: 1 added`, a `moid` |
| Lab 2.1 step 1 | `~ shutdown_wait_timeout = ...`, `Plan: 0 to add, 1 to change, 0 to destroy.` |
| Lab 2.1 step 2-3 | `~ num_cpus ... 1 -> 2`, `~ memory ... 512 -> 1024`, then `--- took Ns`: **note N** (this is the CPU/RAM timing the guide and lab leave unverified), `power: poweredOn`, then a line with `Saved plan is stale` |
| Lab 2.1 step 4 | `# vsphere_virtual_machine.vm will be replaced, as requested`; `moid after replace` is different from `moid before` |
| Lab 2.1 step 5 | `Apply complete! ...` |
| Lab 2.2 | `Plan: 1 to add` after the targeted destroy (with the targeting `Warning`), then `No changes` after the block is deleted |
| Lab 2.3 | five addresses in `state list` (VM plus four `data.`); `serial` and `lineage`; datastore `stats` |
| Lab 2.4 | `govc ok`, `Objects have changed outside of Terraform`, an `annotation` line, then `No changes` after `ignore_changes` |
| cleanup | `Destroy complete!`, then `done` |

**Verify:** the log ends with `done`, and `govc find / -type m` lists no `zz99-*`. If a section is empty or differs, fix it before class. The three items to settle:

- the `--- took` time for the CPU/RAM change (the lab says "about 1 minute at `Still modifying...`"; correct the lab text and the instructor guide if it is not),
- whether `govc ok` printed (`govc vm.change -annotation` works; if not, check `govc vm.change -h` and tell students to use the Host Client),
- if you will use the vCenter path (lockdown): run the script against the vCenter too (Part B.3).

---

## Part B: The workplace ESXi host (for students)

**Who prepares this:** the team's ESXi admin (or you, if you are the admin). Students do not prepare the host; they need only an address, a user and a password.

### B.1 One ESXi user per student

If you do not want to share `root`, give each student a local account. Host Client:

1. *Manage > Security & users > Users > Add user*: name `sNN`, a password.
2. *Host > Actions > Permissions > Add user*: choose `sNN` and the built-in role **Administrator**, which is the simplest role that can create, reconfigure, power and delete VMs.

⚠ Verify on your build: menu names differ slightly between ESXi 7 and 8. A custom role works if it can create VMs, **reconfigure** them (CPU, memory, notes), power them on and off, delete them, and use the datastore and network. Session 2 needs *reconfigure*, which Session 1 did not, so test it (B.5).

An Administrator role on the host also lets a student see and change other VMs. Terraform itself only touches what is in its own state, but remind students that a mistake in the Host Client is still a mistake.

**Verify:** `govc about` works with the student's user (set `GOVC_USERNAME` and `GOVC_PASSWORD`).

### B.2 Lockdown mode

If the host is in lockdown mode (it is managed by a vCenter that blocks direct logins), direct logins fail with `Cannot complete login due to an incorrect user name or password`.

vSphere Client: host > *Configure > Security Profile > Lockdown Mode*. ⚠ Verify on your build: the path differs between ESXi 7 and 8. Two choices:

- Set lockdown to **Disabled** for the lab (or add the student users to the *Exception Users* list).
- Or leave lockdown on and point `VSPHERE_SERVER` at the vCenter. Students then set `datacenter` and `host` in `terraform.tfvars` (see `vm-lab/terraform.tfvars.example`). Find the names as in Session 1 B.2: `govc ls /` and `govc find / -type h` with `GOVC_URL` pointing at the vCenter. **Not verified** with these two variables set to a real vCenter.

**Verify:** `govc about` with the student's credentials succeeds (host: `API type: HostAgent`; vCenter: `VirtualCenter`).

### B.3 Optional: test the vCenter path

Only if you expect lockdown. Run `smoke.sh` (A.3) with `VSPHERE_SERVER` set to the vCenter, and add `datacenter` and `host` to the throwaway `terraform.tfvars` the script writes (edit the script locally: it writes only `student = "zz99"`). Power vCenter on first (10 to 15 minutes), and see the memory note in A.2.

**Verify:** the script reaches `Apply complete!` and cleans up.

### B.4 Free RAM and datastore

Budget per student, at the same time: 1 GB for `sNN-vm01` after the resize, plus 256 MB for `sNN-test01` in Lab 2.2. For 10 students that is about 12.5 GB of free RAM. Disks are thin: 8 GB + 1 GB per student, nearly empty. Keep 10 GB free per student.

```bash
govc ls /ha-datacenter/datastore      # expect datastore1
govc ls /ha-datacenter/network        # expect VM Network
```

For free memory and datastore capacity check `govc host.info -h` and `govc datastore.info -h`, or the Host Client *Host* and *Storage* pages.

**Verify:** `datastore1` and `VM Network` are listed, free RAM is at least 1.25 GB per student, and the datastore has the room. If the names differ, students set `datastore` and `network` in `terraform.tfvars`.

### B.5 Naming and a student test

Every student has a unique `student` ID (`s01`, `s02`, ...). VM names are `sNN-vm01` and `sNN-test01`. Two students with the same ID get `The name '...' already exists`.

Dress rehearsal as a student user (not `root`): run the labs 2.1 to 2.4 with ID `s99` from a laptop.

**Verify:** the resize, the `-replace`, the `destroy`, and the annotation change all work with that user. A missing privilege shows as `NoPermission` with the privilege name.

---

## Part C: Student laptops

Everything from Session 1 Part C applies (Terraform 1.12 or later, git, VS Code). New in Session 2:

- **`jq`** for Labs 2.1 and 2.3 (without it students can still do the labs, but they cannot run the `jq` lines).
- **`govc`** for Lab 2.4 (optional: the Host Client does the same).

| OS | `jq` | `govc` |
|---|---|---|
| macOS | `brew install jq` | `brew install govc` |
| Windows | `winget install jqlang.jq` (open a new terminal afterwards) | download `govc_Windows_x86_64.zip` from `https://github.com/vmware/govmomi/releases` and put `govc.exe` on `PATH`. ⚠ Verify on your build: the file name changes between releases |
| Linux (Debian/Ubuntu) | `sudo apt install -y jq` | `curl -L -o - "https://github.com/vmware/govmomi/releases/latest/download/govc_$(uname -s)_$(uname -m).tar.gz" \| sudo tar -C /usr/local/bin -xvzf - govc` |

**Verify:** `jq --version` prints a version, and `govc about` (with the `GOVC_*` variables set, see C.1) prints the host details.

### C.1 Pre-check

Reuse the Session 1 script:

```bash
export GOVC_URL='https://<ESXI_IP>' GOVC_USERNAME='root' GOVC_PASSWORD='********' GOVC_INSECURE=1
bash labs/session-01/00-precheck/precheck.sh
```

**Verify:** the last line says `Result: N passed, M warnings, 0 failed`. `jq` and `govc` are warnings only, but Session 2 needs `jq`, so install it if the script warns.

### C.2 Session 1 state in the laptop

Students need `labs/session-01/02-first-vm/terraform.tfstate` and `terraform.tfvars` on this laptop. A student who changed `main.tf` in Session 1 needs that file too. Part D.

---

## Part D: Moving the Session 1 state

Lab 2.1 Step 0 moves the Session 1 VM into `vm-lab`:

```bash
cd labs/session-02/vm-lab
mv ../../session-01/02-first-vm/terraform.tfstate .
cp ../../session-01/02-first-vm/terraform.tfvars .
```

**`mv`, not `cp`, for the state.** The state file is Terraform's memory of which VM it owns. If two folders hold a copy, both think they own the VM. A later `destroy` or `-replace` in the old folder deletes the VM that the new folder uses, and the two copies drift apart. `terraform.tfvars` holds only settings, so copying it is fine.

If the student changed `main.tf` in Session 1 (more memory, a `cdrom` block to install Linux), they also run `cp ../../session-01/02-first-vm/main.tf .`.

**Verify:** `terraform init` then `terraform plan` in `vm-lab` ends with `No changes. Your infrastructure matches the configuration.` and the old folder has no `terraform.tfstate`.

Students who lost the state or the VM: `terraform apply` in `vm-lab` builds a new VM. If the VM exists but the state is lost, the apply fails with `already exists`: delete the VM (Part E), then apply. Importing is Session 6.

---

## Part E: Cleanup

Run this for stuck or orphaned VMs, and after Session 2 if the host needs the RAM. Students who still have state should run `terraform destroy` in `vm-lab` first; an admin cleanup leaves their state pointing at nothing, and their next `plan` shows `1 to add`.

```bash
source ~/.govc-esxi.env
govc find / -type m                   # lists every VM; look for sNN-vm01, sNN-test01, zz99-*
govc vm.destroy s01-vm01
govc vm.destroy s01-test01
govc vm.destroy zz99-vm01
govc vm.destroy zz99-test01
```

`govc vm.destroy` powers the VM off first if it is running. Run it once per VM name. The exact names to look for:

| Name | From |
|---|---|
| `sNN-vm01` | The student's main VM (Labs 2.1 to 2.4) |
| `sNN-test01` | The second VM of Lab 2.2 (normally gone by the end of the lab) |
| `zz99-vm01`, `zz99-test01` | `smoke.sh`, left over only if the script failed halfway |

**Verify:** `govc vm.info s01-vm01` prints nothing for that VM, `govc find / -type m` lists no `zz99-*` and no `sNN-test01`, and the Host Client no longer lists them.

After the course: ask students to delete `terraform.tfstate*`, `tfplan`, `.terraform/` and `terraform.tfvars` in `vm-lab`, and to unset the `VSPHERE_*` variables. Remove `~/.govc-esxi.env`, or change the host password if it was shared. Remove ESXi users from B.1 under *Manage > Security & users > Users*.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Cannot complete login due to an incorrect user name or password` | Wrong user or password, or lockdown mode | B.2 |
| `current license or ESXi version prohibits execution of the requested operation` | Free ESXi licence: the API is read-only | A.1 (licence), or follow the demo |
| `x509: certificate signed by unknown authority` | `VSPHERE_ALLOW_UNVERIFIED_SSL` not set | `export VSPHERE_ALLOW_UNVERIFIED_SSL=true`; for govc `GOVC_INSECURE=1` |
| `The name '...' already exists` | Two students with the same `student` ID, or a VM without state | B.5, Part D |
| Plan shows `+ create` for the VM | State not moved, or VM destroyed | Part D |
| Plan shows `memory = 2048 -> 512` | The student's Session 1 `main.tf` was not copied | Part D |
| Power-on fails with `insufficient memory` | The host is out of RAM | B.4; power off other VMs; vCenter off on the demo host (A.2) |
| `Saved plan is stale` | The state changed after `plan -out` | Run `terraform plan -out=tfplan` again |
| Apply waits about 1 minute at `Still modifying...` | `shutdown_wait_timeout = 1` with no VMware Tools | Normal; real timing unverified (A.3) |
| `NoPermission` during resize or power | The ESXi role cannot reconfigure or power VMs | B.1, B.5 |
| `govc: vm 's01-vm01' not found` | `GOVC_*` not set in this shell, or wrong name | `govc find / -type m` |
| `govc vm.change` flag error | Different govc version | Check `govc vm.change -h`; use the Host Client |
| `jq: command not found` | jq not installed | Part C |
| `datacenter '...' not found` or `host '...' not found` (vCenter path) | Wrong names, or the variables are not set | B.2; check `govc ls /` and `govc find / -type h` |
