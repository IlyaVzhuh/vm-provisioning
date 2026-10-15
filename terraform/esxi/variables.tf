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
variable "esxi_password" {
  type      = string
  sensitive = true
}
variable "esxi_ip" {
  type = string
}
variable "datastore" {
  type    = string
  default = "datastore1"
}
variable "network" {
  type    = string
  default = "VM Network"
}
