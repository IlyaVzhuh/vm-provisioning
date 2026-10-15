variable "name" {
  type = string
}
variable "cpu" {
  type = number
}
variable "ram" {
  type = number
}
variable "disk" {
  type = number
}
variable "proxmox_api_url" {
  type = string
}
variable "proxmox_token_id" {
  type = string
}
variable "proxmox_token_secret" {
  type      = string
  sensitive = true
}

variable "node_name" {
  type    = string
  default = "pve1"
}
variable "snippets_datastore" {
  description = "Datastore with the snippets and import content types enabled"
  type        = string
  default     = "local"
}
variable "vm_datastore" {
  type    = string
  default = "local-lvm"
}
variable "cloud_image" {
  description = "Ubuntu cloud image already uploaded to the import storage"
  type        = string
  default     = "local:import/ubuntu-noble.qcow2"
}
