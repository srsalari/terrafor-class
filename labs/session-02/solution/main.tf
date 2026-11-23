# vm-lab/main.tf as it should look at the end of Session 2 (Labs 2.1-2.4).
# The "test" VM from Lab 2.2 is gone again: it was removed from the code.

resource "vsphere_virtual_machine" "vm" {
  name             = "${var.student}-vm01"
  resource_pool_id = data.vsphere_host.esxi.resource_pool_id
  datastore_id     = data.vsphere_datastore.ds.id

  num_cpus = 2
  memory   = 1024
  guest_id = "ubuntu64Guest"

  annotation = "Managed by Terraform. Owner: s01"

  network_interface {
    network_id   = data.vsphere_network.net.id
    adapter_type = "vmxnet3"
  }

  disk {
    label            = "disk0"
    size             = 8
    thin_provisioned = true
  }

  wait_for_guest_net_timeout = 0
  shutdown_wait_timeout      = 1 # minutes; then Terraform powers the VM off

  lifecycle {
    ignore_changes = [annotation]
  }
}
