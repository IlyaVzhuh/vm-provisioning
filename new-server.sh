#!/bin/bash
# Create a VM on ESXi or Proxmox with Terraform, wait for cloud-init, then configure it with Ansible.
# Hypervisors are listed in hosts.conf (see hosts.conf.example), credentials come from Bitwarden CLI.
set -euo pipefail
cd "$(dirname "$0")"
HOSTS=./hosts.conf
[[ -f "$HOSTS" ]] || { echo "no $HOSTS, copy hosts.conf.example"; exit 1; }
export BW_SESSION=${BW_SESSION:-$(bw unlock --raw)}

set_server() {
  echo "hypervisors: $(awk '!/^#/ && NF {printf "%s ", $1}' "$HOSTS")"
  read -p "choose hypervisor: " server
  read -r _ type srvip < <(awk -v n="$server" '!/^#/ && $1 == n' "$HOSTS") || true
  if [[ "${type:-}" == "esxi" ]]; then
    export TF_VAR_esxi_password=$(bw get password "$srvip")
    export TF_VAR_esxi_ip=$srvip
    workdir=./terraform/esxi
  elif [[ "${type:-}" == "proxmox" ]]; then
    export TF_VAR_proxmox_token_id=$(bw get username "${srvip}-terr")
    export TF_VAR_proxmox_token_secret=$(bw get password "${srvip}-terr")
    export TF_VAR_proxmox_api_url="https://${srvip}:8006/"
    workdir=./terraform/proxmox
  else
    echo "unknown hypervisor: $server"
    return 1
  fi
}
until set_server; do :; done

read -p "name of new VM: " name
name=${name:-vm-$RANDOM}
export TF_VAR_name=$name
read -p "num of cpu [4]: " cpu
export TF_VAR_cpu=${cpu:-4}
read -p "RAM size in GB [4]: " ram
export TF_VAR_ram=$(( ${ram:-4} * 1024 ))
read -p "Disk size in GB [15]: " disk
export TF_VAR_disk=${disk:-15}

# every VM gets its own working copy, so its state lives next to it
mkdir -p "$workdir/$name"
cp "$workdir"/*.tf ./user-data.yaml "$workdir/$name/"
cd "$workdir/$name"
terraform init
terraform apply
vmip=$(terraform output -raw vm_ip)
ssh -o StrictHostKeyChecking=accept-new "root@${vmip}" cloud-init status --wait
cd - >/dev/null
ansible-playbook -i "${vmip}," ./ansible/new-serv.yml -u root
