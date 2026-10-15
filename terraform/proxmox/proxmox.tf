#if you need to download ubuntu image
#
#resource "proxmox_download_file" "ubuntu" {
#  node_name = var.node_name
#  datastore_id = var.snippets_datastore
#  content_type = "import"
#  url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
#  file_name = "ubuntu-noble.qcow2"
#  overwrite = false
#}

resource "proxmox_virtual_environment_file" "user_data" {
  node_name    = var.node_name
  datastore_id = var.snippets_datastore
  content_type = "snippets"
  source_raw {
    file_name = "${var.name}-user-data.yaml"
    data      = file("${path.module}/user-data.yaml")
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  name = var.name
  network_device = [{
    bridge       = "vmbr0"
    disconnected = false
    firewall     = true
    enabled      = true
    model        = "virtio"
    mac_address  = null
    mtu          = null
    queues       = null
    rate_limit   = null
    trunks       = null
    vlan_id      = null
  }]
  node_name = var.node_name
  cpu {
    cores   = var.cpu
    numa    = false
    sockets = 1
    type    = "x86-64-v2-AES"
  }
  disk {
    import_from  = var.cloud_image
    datastore_id = var.vm_datastore
    interface    = "scsi0"
    size         = var.disk
    ssd          = true
  }
  memory {
    dedicated      = var.ram
    keep_hugepages = false
  }
  operating_system {
    type = "l26"
  }
  lifecycle {
    prevent_destroy = true
  }
  #cloud-init
  initialization {
    datastore_id = var.snippets_datastore
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.user_data.id
  }
  agent {
    enabled = true
  }
}

output "vm_ip" {
  value = proxmox_virtual_environment_vm.vm.ipv4_addresses[1][0]
}
