# Session 1 lab setup guide (vSphere)

For the instructor or vSphere admin. This guide prepares what Lab 1.2 (`02-first-vm`), Lab 1.3 (`03-vcenter-vm`) and the checklist in [`README.md`](README.md) assume: an ESXi host, a vCenter for the Lab 1.3 demo, student laptops, and a way to clean up.

Every step has a command or a click path, and a **Verify:** line. Names match the lab files (`datastore1`, `VM Network`, VM names `sNN-vm01` and `sNN-vc-vm01`, folder `sNN-lab`). If your environment differs, students change the values in `terraform.tfvars`.

> **Convention.** `sNN` means `s01`, `s02`, ... zero-padded to two digits. Anything marked **⚠ Verify on your build** depends on the vSphere or tool version and must be checked on your own system before class.
>
> **govc.** The commands below use only these subcommands: `about`, `ls`, `find`, `license.ls`, `vm.info`, `vm.destroy`, `object.destroy`, `host.info`, `datastore.info`. For anything else the text says "check `govc <cmd> -h`". Run `govc <cmd> -h` before relying on it.

---

## Overview

Students are online and run Terraform **from their own laptops**. There is no per-student vCenter user, folder, resource pool or role, no template, and no DHCP or SSH requirement in Session 1. The VM is built from scratch (1 vCPU, 512 MB, an empty 8 GB thin disk, no OS), so Session 1 needs no guest OS at all.

| Platform | Who | What works |
|---|---|---|
| **Licensed ESXi** (the team's host) | Students with an account on it | Everything: `init`, `fmt`, `validate`, `plan`, `apply`, `destroy` (Lab 1.2) |
| **Free ESXi**, nested (see [optional-nested-esxi-fa.docx](optional-nested-esxi-fa.docx)) | Students with their own nested host | Everything except `apply`. The free licence makes the API read-only; apply fails with `current license or ESXi version prohibits execution of the requested operation` |
| **No ESXi** (for example Apple Silicon) | Students without a host | `init`, `fmt`, `validate`; they watch `plan` and `apply` in the demo |
| **Instructor server** | Instructor only | HP server, 16 GB RAM, licensed ESXi 8 at `192.168.100.31`, vCenter 8 at `192.168.100.20` |

The instructor server's memory is the limit. vCenter alone takes about 14 GB, so:

- **Lab 1.2 demo** talks to ESXi directly. vCenter can stay off.
- **Lab 1.3 demo** needs vCenter on. Run it last, and destroy its VM right away. Memory is overcommitted.

---

## Part A: Instructor ESXi host

Used for the Lab 1.2 demo and for students who share the team's host.

### A.1 Install govc and connect to the host

macOS: `brew install govc`. Linux:

```bash
curl -L -o - "https://github.com/vmware/govmomi/releases/latest/download/govc_$(uname -s)_$(uname -m).tar.gz" \
  | sudo tar -C /usr/local/bin -xvzf - govc
```

Windows: download `govc_Windows_x86_64.zip` from `https://github.com/vmware/govmomi/releases` and put `govc.exe` on your `PATH`. ⚠ Verify on your build: release file names change between releases.

Connect to the ESXi host. Keep the settings in a file outside the repository:

```bash
cat > ~/.govc-esxi.env <<'EOT'
export GOVC_URL='https://192.168.100.31'
export GOVC_USERNAME='root'
export GOVC_PASSWORD='CHANGE-ME'
export GOVC_INSECURE=1        # self-signed certificate
EOT
chmod 600 ~/.govc-esxi.env
source ~/.govc-esxi.env
```

**Verify:** `govc about` prints `Vendor: VMware, Inc.`, a `Version` of 8.x and `API type: HostAgent` (HostAgent means a standalone ESXi host; vCenter says `VirtualCenter`).

### A.2 Licence

Host Client: *Manage > Licensing*. Or:

```bash
govc license.ls
```

**Verify:** the output lists a real licence key. It must not be an expired evaluation, and not the free "VMware vSphere Hypervisor" licence. A free licence is the cause of the read-only API error in E.3.

### A.3 Datastore and network

```bash
govc ls /ha-datacenter/datastore      # expect datastore1
govc ls /ha-datacenter/network        # expect VM Network
govc datastore.info datastore1        # free space
```

Host Client alternative: *Storage* and *Networking*.

**Verify:** `datastore1` and `VM Network` are listed, and the datastore has room for the class (each VM is a thin 8 GB disk that starts almost empty; keep at least 10 GB free per student). If your names differ, students change `datastore` and `network` in `terraform.tfvars`.

### A.4 Free RAM

Each lab VM has 512 MB. Count 1 GB per VM to be safe.

```bash
govc host.info                        # memory total and usage
```

Host Client: the *Host* page shows memory used and free.

**Verify:** free memory is at least 1 GB times the number of VMs the class will create at once. On the 16 GB instructor server with vCenter powered on, expect very little room (Part B).

### A.5 Lockdown mode

If the host is in lockdown mode, direct logins are blocked and Terraform fails with `Cannot complete login due to an incorrect user name or password`.

Host Client: *Manage > Security & users*, or the vSphere Client: host > *Configure > Security Profile > Lockdown Mode*. It must be **Disabled** for the Lab 1.2 account. ⚠ Verify on your build: the menu path differs between ESXi 7 and 8.

**Verify:** `govc about` with the ESXi credentials succeeds (A.1).

### A.6 Optional: one ESXi user per student (shared host only)

If several students share the host, give each one a local account, so nobody needs the `root` password. Host Client:

1. *Manage > Security & users > Users > Add user*: name `sNN`, a password.
2. *Host > Actions > Permissions > Add user*: choose `sNN` and the built-in role **Administrator**, which is the simplest role that can create VMs.

⚠ Verify on your build: menu names differ slightly between ESXi 7 and 8. A custom role that can create VMs, use the datastore and use the network also works; test it in the dress rehearsal (Part E).

**Verify:** `govc about` works with the new user (set `GOVC_USERNAME` and `GOVC_PASSWORD`), and Lab 1.2 `apply` works with it.

The `student` prefix (`sNN`) keeps VM names apart. Two students with the same prefix get `The name '...' already exists`.

---

## Part B: vCenter for Lab 1.3

Needed only for the Lab 1.3 demo (and for students who have their own vCenter).

### B.1 Power on, in this order

1. The ESXi host `192.168.100.31` is up (A.1).
2. Power on the vCenter VM from the Host Client (*Virtual Machines > vCenter > Power on*).
3. Wait 10 to 15 minutes until the vSphere Client at `https://192.168.100.20` answers.

> **16 GB warning.** vCenter alone takes about 14 GB of the server's 16 GB. The Lab 1.3 VM (512 MB) can power on only because memory is overcommitted, and the host may swap. Power off other VMs first, run Lab 1.3 **last**, and destroy its VM right away (Part F).

**Verify:** with `GOVC_URL=https://192.168.100.20` and the vCenter user and password set, `govc about` prints `API type: VirtualCenter`.

### B.2 Find the datacenter and host names

Lab 1.3 needs the exact names in `terraform.tfvars`.

```bash
export GOVC_URL='https://192.168.100.20'
export GOVC_USERNAME='administrator@vsphere.local'
export GOVC_PASSWORD='CHANGE-ME'
export GOVC_INSECURE=1

govc ls /                             # the datacenters, for example /DC-Lab
govc find / -type h                   # the hosts, for example /DC-Lab/host/192.168.100.31
```

vSphere Client alternative: the *Hosts and Clusters* view. The host is listed under the datacenter, often by its IP address.

**Verify:** you can fill in `datacenter = "<name>"` and `host = "<name as listed>"`. The host is the last part of the path, for example `192.168.100.31`. Names are case-sensitive.

### B.3 User permissions

For the demo, use `administrator@vsphere.local`. Any other user needs, on the datacenter (propagated to children):

- `Folder.Create`, to create the `sNN-lab` folder, and
- the privileges to create a VM on the host, datastore and network.

The simplest way is the built-in **Administrator** role on the datacenter. ⚠ Verify on your build: check the privilege names in the vSphere Client under *Administration > Access Control > Roles*.

**Verify:** run the Lab 1.3 `plan` and `apply` as that user. A missing privilege shows as `NoPermission` with the privilege name.

---

## Part C: Student laptops

On every laptop install Terraform 1.12 or later, git, VS Code (optional) and govc (optional; the labs do not need it). Pin a **single Terraform version for the whole class** (at least 1.12.0, which is the `required_version` in `versions.tf` and the `MIN_TF` in `precheck.sh`). Pick the version once (for example `TF_VERSION=1.12.2`; ⚠ Verify on your build that it exists on `https://releases.hashicorp.com/terraform/`) and tell everyone.

### C.1 macOS (Homebrew)

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
brew install git jq govc
brew install --cask visual-studio-code
```

Homebrew installs the newest release. To pin an exact version, use the manual download in C.5.

### C.2 Windows

winget (PowerShell):

```powershell
winget install --id Hashicorp.Terraform
winget install --id Git.Git
winget install --id Microsoft.VisualStudioCode
winget install --id jqlang.jq
```

A specific version with winget: `winget install --id Hashicorp.Terraform --version 1.12.2` (check `winget show --id Hashicorp.Terraform --versions`).

Chocolatey (an alternative):

```powershell
choco install terraform git vscode jq govc -y
# pinned:  choco install terraform --version=1.12.2 -y
```

⚠ Verify on your build: package IDs (`Hashicorp.Terraform`, `jqlang.jq`) and the existence of a `govc` Chocolatey package. If `govc` is not available, use the `govc_Windows_x86_64.zip` from the govmomi releases page (the govmomi releases page).

### C.3 Linux (Debian/Ubuntu, HashiCorp apt repository)

```bash
sudo apt update && sudo apt install -y gnupg curl lsb-release software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform git jq unzip
```

To pin: `apt-cache madison terraform` lists the versions; then `sudo apt install terraform=<version-from-madison>` and `sudo apt-mark hold terraform`.

govc on Linux (optional):

```bash
curl -L -o - "https://github.com/vmware/govmomi/releases/latest/download/govc_$(uname -s)_$(uname -m).tar.gz" \
  | sudo tar -C /usr/local/bin -xvzf - govc
```

### C.4 VS Code and the HashiCorp Terraform extension

Install VS Code (C.1 to C.3), then:

```bash
code --install-extension hashicorp.terraform
```

(Or *Extensions* view > search "HashiCorp Terraform" > Install.)

**Verify:** `code --list-extensions | grep hashicorp.terraform` prints the ID.

### C.5 Pin the class's Terraform version (manual download)

Use this on any OS when you need an exact version, or for offline classes.

```bash
TF_VERSION=1.12.2                                    # ⚠ Verify on your build: pick the class version
OS=linux; ARCH=amd64                                 # or: darwin / arm64, windows / amd64
curl -fsSLO "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_${OS}_${ARCH}.zip"
curl -fsSLO "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_SHA256SUMS"
grep "terraform_${TF_VERSION}_${OS}_${ARCH}.zip" "terraform_${TF_VERSION}_SHA256SUMS" | sha256sum -c -    # macOS: shasum -a 256 -c -
unzip terraform_${TF_VERSION}_${OS}_${ARCH}.zip
sudo mv terraform /usr/local/bin/
```

**Verify:** `terraform version` prints exactly `Terraform v${TF_VERSION}` for every student. To catch a drift in the lab, `versions.tf` already requires `>= 1.12.0`.

### C.6 Finish: run the pre-check

The ESXi login test is optional. To include it, set the `GOVC_*` variables for the host the student will use:

```bash
export GOVC_URL='https://<ESXI_IP>'
export GOVC_USERNAME='root'             # or the student's ESXi user
export GOVC_PASSWORD='********'
export GOVC_INSECURE=1

cd labs/session-01/00-precheck
chmod +x precheck.sh
./precheck.sh
```

**Verify:** the last line says `Result: N passed, M warnings, 0 failed`, and the script exits 0. `govc`, `jq`, `aws` and `code` are warnings only (AWS is used from Session 5). Failures name the missing tool or the host that cannot be reached. Students with no ESXi or only a free ESXi still pass: they simply cannot `apply`.

---

## Part D: Offline / provider mirror (optional)

Use this if laptops cannot reach `registry.terraform.io`, `releases.hashicorp.com` or GitHub. You build a **provider mirror** on a machine that has internet access and hand it to students on a USB drive or a file share.

### D.1 Build the mirror (on a machine with internet)

Create a working folder that declares the providers, then mirror them. Mirror **every provider that Session 1 labs use**: run the command for `01-providers` as well as for `02-first-vm`, into the same mirror directory. `03-vcenter-vm` uses the same provider as `02-first-vm`, so it needs no extra mirror.

```bash
mkdir -p ~/tf-mirror
cd labs/session-01/02-first-vm
terraform providers mirror \
  -platform=linux_amd64 -platform=darwin_arm64 -platform=darwin_amd64 -platform=windows_amd64 \
  ~/tf-mirror

cd ../01-providers
terraform providers mirror \
  -platform=linux_amd64 -platform=darwin_arm64 -platform=darwin_amd64 -platform=windows_amd64 \
  ~/tf-mirror
```

`terraform providers mirror` reads the configuration in the current directory and downloads the packages that satisfy its version constraints for the platforms you list with `-platform` (repeat the flag for each OS and CPU in your class). Copy the Terraform binary zip for each OS (Part C.5) into the same share, because the binary also comes from `releases.hashicorp.com`.

**Verify:** `find ~/tf-mirror -name '*.zip'` lists one zip per provider and platform, under `registry.terraform.io/vmware/vsphere/` (the directory layout is `<host>/<namespace>/<type>/`, with `terraform-provider-vsphere_<version>_<os>_<arch>.zip` files).

### D.2 Point Terraform at the mirror (on each laptop)

Create the CLI configuration file. Location: `~/.terraformrc` on macOS and Linux, `%APPDATA%\terraform.rc` on Windows. (The environment variable `TF_CLI_CONFIG_FILE` can name a different file.)

```hcl
provider_installation {
  filesystem_mirror {
    path    = "/opt/terraform-mirror"
    include = ["registry.terraform.io/vmware/vsphere", "registry.terraform.io/hashicorp/*"]
  }
  direct {
    exclude = ["registry.terraform.io/vmware/vsphere", "registry.terraform.io/hashicorp/*"]
  }
}
```

On Windows, write the path with forward slashes, for example `path = "C:/terraform-mirror"`.

How it works:
- `filesystem_mirror` serves the packages from a directory on disk. `include` limits it to the providers listed.
- `direct` installs from the origin registry. `exclude` here means "never go to the internet for these". Together, listed providers come only from the mirror, and any other provider (not listed in either) would still be fetched directly.
- To forbid all internet access, replace the `direct` block with `direct { exclude = ["*/*/*"] }`.

Copy the mirror folder (`~/tf-mirror`) to the path named in `path`.

**Verify:** in `labs/session-01/02-first-vm`, run `terraform init`. The output says `Installing vmware/vsphere v... (unauthenticated)` or similar, and it succeeds with no network access to `github.com`. Check with `terraform providers`. The lock file is written. ⚠ Verify on your build: providers installed from a mirror get hashes only for the mirror's platforms in `.terraform.lock.hcl`; if students on different platforms share one lock file, run `terraform providers lock -fs-mirror=<path> -platform=...` (check `terraform providers lock -h`).

---

---

## Part E: Dress rehearsal

Run both labs end to end from a laptop (not from the instructor server), as the same kind of user the students will use. Do this the day before.

### E.1 Lab 1.2 against ESXi

```bash
cd labs/session-01/02-first-vm
export VSPHERE_SERVER="192.168.100.31" VSPHERE_USER="root" VSPHERE_PASSWORD='********' VSPHERE_ALLOW_UNVERIFIED_SSL=true
cp terraform.tfvars.example terraform.tfvars        # set student = "s99"
terraform init
terraform fmt -check          # lists outputs.tf, exit status 3 (bad format on purpose)
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output
terraform plan                # No changes
```

**Expected:**
- `init`: `Installing vmware/vsphere v2.x.y`.
- `validate`: `Success! The configuration is valid.`
- `plan`: `Plan: 1 to add, 0 to change, 0 to destroy.` Data sources are read, not created.
- `apply`: `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.` after a few seconds, then the outputs `vm_name = "s99-vm01"`, `vm_power_state = "poweredOn"`, `vm_moid` (a number) and `vm_uuid`.
- The VM `s99-vm01` appears in the Host Client. Its console shows no operating system, which is correct.

**Verify:** `govc vm.info s99-vm01` (with `GOVC_URL` pointing at the ESXi host) shows `Power state: poweredOn`. If power-on fails with `insufficient memory`, see the Troubleshooting table.

### E.2 Lab 1.3 against vCenter

Power on vCenter first (Part B). Then:

```bash
cd labs/session-01/03-vcenter-vm
export VSPHERE_SERVER="192.168.100.20" VSPHERE_USER="administrator@vsphere.local" VSPHERE_PASSWORD='********' VSPHERE_ALLOW_UNVERIFIED_SSL=true
cp terraform.tfvars.example terraform.tfvars        # set student, datacenter, host from B.2
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

**Expected:**
- `plan`: `Plan: 2 to add, 0 to change, 0 to destroy.` (the folder and the VM).
- `apply`: `vsphere_folder.lab` is created first, then `vsphere_virtual_machine.vm`; `Apply complete! Resources: 2 added`.
- The VM `s99-vc-vm01` sits in the folder `s99-lab` in the *VMs and Templates* view.
- `destroy`: the VM goes first, then the folder; `Destroy complete! Resources: 2 destroyed.`

**Verify:** with `GOVC_URL` pointing at vCenter, `govc ls /<datacenter>/vm` no longer shows `s99-lab`.

### E.3 Negative check: free ESXi cannot apply

On a nested free ESXi, repeat E.1. `init`, `fmt`, `validate` and `plan` work. `apply` fails with:

```text
current license or ESXi version prohibits execution of the requested operation
```

**Verify:** you see that message at `apply`, and `govc vm.info s99-vm01` finds no VM. This is the expected result. It also shows the difference between read calls (work) and write calls (blocked), which the instructor uses in the 2:25 block.

### E.4 Clean up the rehearsal

Part F, with `s99`.

---

## Part F: Cleanup

Run this when a VM is no longer needed: right after the Lab 1.3 demo, and after Session 2 for the student VMs. Students who still have state should run `terraform destroy` from their lab folder first; an admin cleanup leaves their local state pointing at nothing.

### F.1 Lab 1.2 VMs (ESXi)

```bash
source ~/.govc-esxi.env
govc find / -type m                   # lists every VM; look for sNN-vm01
govc vm.destroy s01-vm01
```

`govc vm.destroy` powers the VM off first if it is running.

**Verify:** `govc vm.info s01-vm01` prints nothing for that VM, and the Host Client no longer lists it.

### F.2 Lab 1.3 VMs and folders (vCenter)

```bash
export GOVC_URL='https://192.168.100.20'      # username, password and GOVC_INSECURE as in B.2
govc find / -type m                           # look for sNN-vc-vm01
govc vm.destroy s01-vc-vm01
govc ls /<datacenter>/vm                      # look for sNN-lab
govc object.destroy /<datacenter>/vm/s01-lab  # the folder must be empty first
```

**Verify:** `govc ls /<datacenter>/vm` shows no `sNN-lab` folder. Then power vCenter off if you do not need it: it frees about 14 GB.

### F.3 Laptops and accounts

Ask students to delete `terraform.tfstate*`, `.terraform/` and `terraform.tfvars` in the lab folders after `destroy`, and to unset the `VSPHERE_*` variables. Delete the provider mirror and `~/.terraformrc` (Part D) from shared drives. Remove `~/.govc-esxi.env`, or change the host password if it was shared. If you created ESXi users (A.6), remove them under *Manage > Security & users > Users*.

**Verify:** `govc find / -type m` lists no `sNN` VMs on either the ESXi host or vCenter.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `govc about` fails with a certificate error | `GOVC_INSECURE` is not set | `export GOVC_INSECURE=1` |
| `x509: certificate signed by unknown authority` in Terraform | `VSPHERE_ALLOW_UNVERIFIED_SSL` is not set | `export VSPHERE_ALLOW_UNVERIFIED_SSL=true` |
| `Cannot complete login due to an incorrect user name or password` | Wrong user or password, or the host is in lockdown mode | Check A.5 and A.6 |
| `current license or ESXi version prohibits execution of the requested operation` | Free ESXi licence: the API is read-only | Use a licensed host, or follow the demo (E.3) |
| `datastore '...' not found` or `network '...' not found` | Different names on this host | A.3; change `terraform.tfvars` |
| `The name '...' already exists` | Two students use the same `student` value on one host | A unique `sNN` per student |
| Power-on fails with `insufficient memory` | The host is out of RAM | Power off other VMs (or vCenter, if it is not needed); see the instructor guide |
| Lab 1.3 `datacenter '...' not found` or `host '...' not found` | Typo or wrong case | B.2; copy the names from the vSphere Client |
| Lab 1.3 `NoPermission` ... `Folder.Create` | The vCenter user cannot create folders | B.3 |
| Lab 1.3 `Cannot complete login` | ESXi credentials used against vCenter | Use `user@vsphere.local` |
| `terraform init`: `Failed to query available provider packages` or timeouts | A firewall blocks `registry.terraform.io` | Open it, or use the mirror (Part D) |
| `terraform init`: the provider download fails but the registry works | `github.com` (where the vSphere provider is hosted) is blocked | Open it, or use the mirror |
| `terraform init`: `no available releases match` | The mirror lacks this OS, CPU or version | Rebuild the mirror with the right `-platform` values |
| `precheck.sh` says `terraform ... is older than 1.12.0` | Old Terraform on the laptop | C.5 |
| `precheck.sh` cannot reach a host | Firewall or proxy | Allow `registry.terraform.io`, `releases.hashicorp.com` and `github.com` |
