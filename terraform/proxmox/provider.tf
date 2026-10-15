terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.115.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_token_id}=${var.proxmox_token_secret}"
  insecure  = true
  ssh {
    agent       = true
    username    = "root"
    private_key = file("~/.ssh/id_ed25519")
  }
}
