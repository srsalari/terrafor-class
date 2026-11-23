# Session 1 Recap Quiz

This quiz takes about 10 minutes.

---

**1. (1a, 1b)** Your team currently builds VMs by clicking through the vSphere Client. Which is an advantage of defining the same VMs with Infrastructure as Code instead?

- A. The configuration can be stored in version control, reviewed, and applied repeatedly with consistent results.
- B. Terraform no longer needs to track what it has created.
- C. Configuration drift becomes impossible.
- D. No credentials are needed to reach ESXi or vCenter.

---

**2. (1c)** True or false: Because Terraform is service-agnostic, you can move a `vsphere_virtual_machine` resource block to AWS by changing only the provider configuration.

- A. True
- B. False

---

**3. (2a)** A configuration declares the vSphere provider with `version = "~> 2.6"`. Which provider version satisfies this constraint?

- A. 3.0.0
- B. 2.5.9
- C. 2.18.0
- D. 1.99.0

---

**4. (2a)** Which TWO statements about `.terraform.lock.hcl` are correct? (Choose two.)

- A. It records the exact provider versions selected during `terraform init`, along with their checksums.
- B. It records the exact versions of the modules the configuration calls.
- C. It is normally committed to version control so teammates and CI install the same provider versions.
- D. Every `terraform plan` rewrites it to the newest provider version allowed by the constraint.

---

**5. (2a, 2b)** An older configuration declares `source = "hashicorp/vsphere"` and is stuck on version 2.12. The team wants the current vSphere provider releases (2.18 and newer). What must change?

- A. Raise the version constraint to `>= 2.13` and keep the `hashicorp/vsphere` source.
- B. Change the source address to `vmware/vsphere`, then run `terraform init`.
- C. Keep the source and run `terraform init -upgrade`.
- D. Set `required_version` in the `terraform` block to a newer Terraform version.

---

**6. (3a, 3b, 2b)** You clone a repository that has a `required_providers` block and no `.terraform` directory. Which describes what `terraform init` does?

- A. It creates the VMs and networks described in the configuration.
- B. It installs the required providers into the `.terraform` directory, writes or updates the dependency lock file, and initializes the backend.
- C. It compares the configuration to the real infrastructure and prints the changes Terraform would make.
- D. It upgrades every provider already in the lock file to the newest allowed version.

---

**7. (3c, 3g)** You are in a fresh checkout with no `terraform init` run yet and no ESXi or vCenter credentials set. Which TWO statements are correct? (Choose two.)

- A. `terraform fmt -check -recursive` can run, because `fmt` does not need providers or init.
- B. `terraform validate` can run immediately, because it only reads the `.tf` files.
- C. After `terraform init` has installed the providers, `terraform validate` can run without ESXi or vCenter credentials.
- D. `terraform fmt -check` rewrites any badly formatted files and exits with status 0.

---

**8. (4a)** A configuration contains `data "vsphere_datacenter" "dc" { name = "dc-01" }`, and other resources reference `data.vsphere_datacenter.dc.id`. What happens to the datacenter when you run `terraform destroy`?

- A. Terraform deletes the datacenter from vCenter.
- B. Terraform deletes the datacenter only if no VMs remain in it.
- C. Nothing happens to the datacenter. A data source only reads an existing object, and Terraform does not manage its lifecycle.
- D. The destroy fails, because data sources cannot be destroyed.

---

<details><summary>Answers</summary>

1. **A.** Version-controlled, declarative configuration is reviewable, repeatable, and consistent. B is wrong because Terraform still uses state. C is wrong because drift can still happen and is detected by `plan`. D is wrong because Terraform still needs credentials to call the ESXi or vCenter API.

2. **B (False).** The workflow is the same across platforms, but resource types are provider-specific. A `vsphere_virtual_machine` has no AWS equivalent, so you would rewrite it as an `aws_instance`.

3. **C.** `~> 2.6` means `>= 2.6` and `< 3.0`, so 2.18.0 fits. 3.0.0 is over the ceiling, and 2.5.9 and 1.99.0 are under the floor.

4. **A and C.** The lock file pins provider versions and checksums, and it should be committed. B is wrong because the lock file tracks providers only, not modules. D is wrong because the file changes only on `terraform init` (for example `-upgrade`), never on `plan`.

5. **B.** `hashicorp/vsphere` is a different source address that stopped at 2.12, so only changing the source to `vmware/vsphere` gets newer releases (the short form expands to `registry.terraform.io/vmware/vsphere`). A and C cannot work because no newer versions exist under the old address. D is wrong because `required_version` constrains Terraform itself, not providers. If state already references the old provider, run `terraform state replace-provider` as well.

6. **B.** `init` is the step between write and plan. It downloads providers into `.terraform/`, writes or updates `.terraform.lock.hcl`, and sets up the backend. A describes `apply`, and C describes `plan`. D is wrong because upgrading beyond the locked versions requires `-upgrade`.

7. **A and C.** `fmt` only reformats or checks text, so it needs neither init nor credentials. `validate` needs providers installed (so `init` first) to check resource schemas, but it makes no API calls, so no credentials are needed. B is wrong because `validate` needs init. D is wrong because `-check` never modifies files and exits non-zero (3) when formatting is needed.

8. **C.** A data block reads an existing object, which is how the labs looked up the datacenter, datastore, network, and host. Only objects declared in `resource` blocks are created or destroyed by Terraform, so the datacenter is untouched. A and B are wrong for that reason. D is wrong because destroy succeeds and data sources simply do nothing.

</details>
