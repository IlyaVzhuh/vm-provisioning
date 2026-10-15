
# started from `terraform plan -generate-config-out` of an existing VM, then parameterised
resource "esxi_guest" "vm" {
  boot_disk_size = var.disk
  boot_disk_type = null
  boot_firmware  = "efi"
  #  clone_from_vm      = "template"
  disk_store         = var.datastore
  guest_name         = var.name
  guestinfo          = null
  guestos            = "ubuntu-64"
  host_ovf           = null
  memsize            = var.ram
  notes              = ""
  numvcpus           = var.cpu
  ovf_source         = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.ova"
  power              = "on"
  resource_pool_name = "/"
  virthwver          = "20"
  network_interfaces {
    nic_type        = "vmxnet3"
    virtual_network = var.network
  }
  ovf_properties {
    key   = "hostname"
    value = var.name
  }
  ovf_properties {
    key   = "public_keys"
    value = file("~/.ssh/id_ed25519.pub")
  }
  ovf_properties {
    key   = "user-data"
    value = base64encode(file("${path.module}/user-data.yaml"))
  }
}

output "vm_ip" {
  value = esxi_guest.vm.ip_address
}
