# Session 2 Recap Quiz

This quiz takes about 10 minutes.

---

**1. (3d)** In the output of `terraform plan`, a resource is shown with the symbol `-/+`. What does it mean?

- A. The resource is updated in place and keeps its ID.
- B. The resource is removed from the state but not destroyed on the platform.
- C. The resource is destroyed and a replacement is created.
- D. The resource is only read, because it is a data source.

---

**2. (3d, 3e)** You run `terraform plan -out=tfplan`, review the plan, and then run `terraform apply tfplan`. Which TWO statements are correct? (Choose two.)

- A. Terraform creates a new plan at apply time and asks you to confirm it with `yes`.
- B. Terraform applies the saved plan without asking for confirmation.
- C. The plan file is safe to commit to version control, because it contains no variable values.
- D. If the state changed after the plan was created, the apply fails with an error that the saved plan is stale.

---

**3. (3e)** A VM managed by Terraform is damaged in a way Terraform cannot detect, and `terraform plan` shows no changes. Without editing the configuration, how do you make Terraform replace it, with the replacement shown in the plan before anything happens?

- A. `terraform apply -replace="vsphere_virtual_machine.vm"`
- B. `terraform taint vsphere_virtual_machine.vm`, which is the recommended method in current versions
- C. `terraform apply -refresh-only`
- D. `terraform state rm vsphere_virtual_machine.vm`

---

**4. (3f)** You want to see what `terraform destroy` would remove, without removing anything. Which command does this?

- A. `terraform destroy -dry-run`
- B. `terraform plan -refresh-only`
- C. `terraform state list`
- D. `terraform plan -destroy`

---

**5. (3f)** Which TWO statements about the `-target` option are correct? (Choose two.)

- A. Terraform prints a warning that resource targeting is in effect and is not for routine use.
- B. It permanently removes the targeted resource from the configuration.
- C. It is meant for exceptional situations, such as recovering from an error.
- D. After `terraform destroy -target=<address>`, a normal `terraform plan` shows no changes, even if the resource is still in the code.

---

**6. (2d, 6a)** A working directory has no `backend` block. Where does Terraform store the state after `terraform apply`?

- A. In the `.terraform` directory.
- B. In a file named `terraform.tfstate` in the working directory.
- C. On the platform the provider manages, for example as a property of the VM.
- D. Nowhere. Terraform reads the real infrastructure again at every run.

---

**7. (7b, 2d)** A configuration has one `vsphere_virtual_machine` resource and four `data` sources. Which TWO statements are correct? (Choose two.)

- A. `terraform state list` queries the platform and prints the VMs it finds.
- B. `terraform state list` prints the addresses of all five objects, including `data.vsphere_datastore.ds`.
- C. Data sources are not stored in the state, because Terraform never changes them.
- D. `terraform show -json` prints the state in a machine-readable format intended for scripts and tools.

---

**8. (6d)** Someone changed a VM's note in the Host Client. You want Terraform's state to record the new value, and you do not want Terraform to change the VM. What do you run?

- A. `terraform apply`
- B. `terraform plan -refresh=false`
- C. `terraform apply -refresh-only`
- D. `terraform state rm vsphere_virtual_machine.vm`

---

<details><summary>Answers</summary>

1. **C.** `-/+` means destroy, then create a replacement. `~` is an update in place (A). `-` alone is a destroy. Reading a data source is shown as `<=` (D). Removing something from state only is not a plan symbol (B). `+/-` is also a replacement, but the new object is created first (`create_before_destroy`).

2. **B and D.** A saved plan is applied as it is, with no confirmation prompt, because you already reviewed it (so A is wrong). It is tied to the state it was made from, so after the state changes (including after the same plan has been applied once), apply fails with `Saved plan is stale` (D). C is wrong: a plan file can contain variable values and other sensitive data in plain text, so it must not be committed.

3. **A.** `-replace=<address>` forces the replacement and is part of a normal plan, so it can be reviewed first. `terraform taint` still exists but is deprecated, and it edits the state before any plan is shown (B). `-refresh-only` only updates the state (C). `state rm` removes the VM from state without destroying it, so the next apply would try to create a second VM and fail on the name (D).

4. **D.** `terraform plan -destroy` shows the destroy plan and changes nothing. `terraform destroy` has no `-dry-run` option (A). `-refresh-only` is about drift (B). `state list` only prints addresses in the state (C).

5. **A and C.** Terraform warns on every use, and `-target` is for exceptional cases. B is wrong: `-target` never edits the configuration. D is wrong: the code still declares the resource, so the next plan wants to create it again. The right way to remove a resource is to delete its code.

6. **B.** Without a `backend` block Terraform uses the local backend, which writes `terraform.tfstate` in the working directory (and `terraform.tfstate.backup` as the previous version). `.terraform` holds providers and backend settings, not state (A). The platform keeps no copy of Terraform's state (C). D is wrong, because the state is how Terraform knows which real objects belong to the configuration.

7. **B and D.** `state list` reads the state only and prints all addresses, including data sources, which are stored with the values they last read (so A and C are wrong). `terraform show -json` is the stable, machine-readable format.

8. **C.** `apply -refresh-only` updates the state to match reality and never changes the VM. A would change the note back to what the code says. B skips the refresh, so the new value is not seen. D removes the VM from state, so Terraform would try to create it again. Note: the code still has the old value, so a normal plan afterwards will still propose to change the note back, unless you change the code or use `ignore_changes`.

</details>
