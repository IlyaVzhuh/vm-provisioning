# vm-provisioning

Одна команда создаёт новую виртуальную машину на VMware ESXi или Proxmox VE и доводит её до рабочего состояния: Terraform создаёт ВМ, cloud-init делает первичную настройку, Ansible ставит обновления и Docker.

```
./new-server.sh
  ├─ выбор гипервизора из hosts.conf, учётные данные из Bitwarden CLI
  ├─ terraform apply      → ВМ из Ubuntu 24.04 cloud-image (Proxmox: bpg/proxmox, ESXi: josenk/esxi)
  ├─ cloud-init           → пользователь, SSH-ключ, qemu-guest-agent / open-vm-tools
  └─ ansible-playbook     → расширение диска, full-upgrade с перезагрузкой при необходимости, Docker
```

## Зачем

До этого ВМ создавались вручную через веб-интерфейс, и каждая получалась немного другой. Теперь машина создаётся за несколько минут, а её параметры описаны в коде.

## Что внутри

| Путь | Что делает |
| --- | --- |
| `new-server.sh` | Интерактивный сценарий: спрашивает имя, CPU, RAM и диск, затем запускает Terraform и Ansible |
| `terraform/proxmox/` | ВМ на Proxmox: диск импортируется из cloud-image, user-data загружается как snippet, используется API-токен с отдельной ролью |
| `terraform/esxi/` | ВМ на ESXi из OVA cloud-image, user-data передаётся через OVF properties |
| `user-data.yaml` | cloud-init: SSH-ключ, часовой пояс, гостевой агент |
| `ansible/grow-disk.yml` | Расширяет корневой раздел на весь диск: работает и с обычным разделом, и с LVM |
| `ansible/full-upgrade.yml` | `apt dist-upgrade`, перезагрузка только если она нужна (`/var/run/reboot-required`) |
| `ansible/docker-install.yml` | Docker CE из официального репозитория (deb822 sources) |

## Безопасность

- Пароли и токены не хранятся в репозитории: `new-server.sh` берёт их из Bitwarden и передаёт в Terraform через `TF_VAR_*`.
- Для Proxmox используется отдельный API-токен с ролью, в которой только нужные привилегии, а не root.
- У ВМ стоит `lifecycle { prevent_destroy = true }`. Однажды из-за лишнего `import`-блока `terraform plan` предложил удалить рабочую ВМ, и именно эта настройка не дала этому случиться.
- State каждой ВМ лежит в её собственной папке и в git не попадает (см. `.gitignore`).

## Запуск

```bash
cp hosts.conf.example hosts.conf          # свои гипервизоры
bw login                                  # Bitwarden CLI
# в Bitwarden: ESXi — запись "<ip>" с паролем; Proxmox — "<ip>-terr" (username = token id, password = secret)
./new-server.sh
```

Требуется: Terraform ≥ 1.6, Ansible ≥ 2.15 (+ `community.general`), Bitwarden CLI, SSH-ключ `~/.ssh/id_ed25519`.

## Что планирую добавить

- remote state (S3/MinIO) с блокировкой вместо локального файла
- модуль Terraform вместо копирования `.tf` в папку каждой ВМ
- Ansible-роли вместо отдельных плейбуков
