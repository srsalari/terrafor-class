#!/usr/bin/env bash
# Session 2 smoke test for the instructor: runs every risky step of Labs 2.1-2.4
# against a real ESXi host, in a throwaway copy of vm-lab, with VM names zz99-*.
# It creates and destroys its own VMs only. Paste the whole output back.
#
# Needs: terraform, jq, govc; VSPHERE_SERVER / VSPHERE_USER / VSPHERE_PASSWORD /
#        VSPHERE_ALLOW_UNVERIFIED_SSL=true exported.
# Usage: ./smoke.sh
set -u
here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
cp "$here"/vm-lab/*.tf "$work"/
cd "$work" || exit 1
echo 'student = "zz99"' > terraform.tfvars
export GOVC_URL=$VSPHERE_SERVER GOVC_USERNAME=$VSPHERE_USER GOVC_PASSWORD=$VSPHERE_PASSWORD GOVC_INSECURE=1

step() { echo; echo "=== $1  ($(date +%T))"; }
t0() { s=$(date +%s); }
t1() { echo "--- took $(( $(date +%s) - s ))s"; }
tf() { terraform "$@" -no-color 2>&1 | grep -vE '^\s*$|Reading\.\.\.|Read complete|Refreshing state' ; return "${PIPESTATUS[0]}"; }

step "init + apply (baseline VM)"
tf init -input=false >/dev/null && echo "init ok"
t0; tf apply -auto-approve -input=false | tail -8; t1
moid1=$(terraform output -raw vm_moid); echo "moid before: $moid1"

step "Lab 2.1 step 1: add shutdown_wait_timeout (expect update in-place, no VM change)"
perl -0pi -e 's/(  wait_for_guest_net_timeout = 0\n)/$1  shutdown_wait_timeout = 1\n/' main.tf
tf plan -input=false | grep -E 'shutdown_wait|Plan:'
tf apply -auto-approve -input=false | tail -2

step "Lab 2.1 step 2-3: CPU 2 / RAM 1024 on a running VM with no OS (TIMED)"
perl -pi -e 's/num_cpus = 1/num_cpus = 2/; s/memory   = 512/memory   = 1024/' main.tf
tf plan -out=tfplan -input=false | grep -E 'num_cpus|memory|Plan:'
t0; tf apply tfplan | tail -4; t1
echo "moid after resize: $(terraform output -raw vm_moid)  power: $(terraform output -raw vm_power_state)"
echo "re-apply stale plan (expect 'Saved plan is stale'):"; tf apply tfplan | grep -i stale

step "Lab 2.1 step 4: -replace (expect new moid)"
t0; tf apply -auto-approve -input=false -replace=vsphere_virtual_machine.vm | grep -E 'replaced|Apply complete'; t1
echo "moid after replace: $(terraform output -raw vm_moid)  (before: $moid1)"

step "Lab 2.1 step 5: annotation"
perl -0pi -e 's/(  guest_id = "ubuntu64Guest"\n)/$1  annotation = "Managed by Terraform. Owner: zz99"\n/' main.tf
tf apply -auto-approve -input=false | tail -1

step "Lab 2.2: second VM, -target destroy, plan afterwards"
cat >> main.tf <<'EOF'

resource "vsphere_virtual_machine" "test" {
  name             = "${var.student}-test01"
  resource_pool_id = data.vsphere_host.esxi.resource_pool_id
  datastore_id     = data.vsphere_datastore.ds.id
  num_cpus         = 1
  memory           = 256
  guest_id         = "ubuntu64Guest"
  network_interface {
    network_id   = data.vsphere_network.net.id
    adapter_type = "vmxnet3"
  }
  disk {
    label            = "disk0"
    size             = 1
    thin_provisioned = true
  }
  wait_for_guest_net_timeout = 0
}
EOF
tf apply -auto-approve -input=false | tail -1
tf destroy -auto-approve -input=false -target=vsphere_virtual_machine.test | grep -E 'Warning|Destroy complete'
tf plan -input=false | grep -E 'Plan:|No changes'   # expect 1 to add
perl -0pi -e 's/\nresource "vsphere_virtual_machine" "test".*//s' main.tf
tf plan -input=false | grep -E 'Plan:|No changes'   # expect No changes

step "Lab 2.3: state"
terraform state list
jq '{serial, lineage}' terraform.tfstate
terraform show -json | jq -c '.values.root_module.resources[] | {address, mode}'
terraform state show data.vsphere_datastore.ds | grep -A4 stats

step "Lab 2.4: drift via govc annotation"
govc vm.change -vm zz99-vm01 -annotation "Changed by hand" && echo "govc ok"
tf plan -input=false | grep -E 'changed outside|annotation|Plan:'
tf apply -refresh-only -auto-approve -input=false | tail -2
tf plan -input=false | grep -E 'annotation|Plan:|No changes'
perl -0pi -e 's/(  wait_for_guest_net_timeout = 0\n)/$1  lifecycle {\n    ignore_changes = [annotation]\n  }\n/' main.tf
tf plan -input=false | grep -E 'Plan:|No changes'

step "cleanup"
tf destroy -auto-approve -input=false | tail -1
cd / && rm -rf "$work"
echo "done"
