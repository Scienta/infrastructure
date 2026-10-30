terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.103.0"
    }
  }
}

locals {
  node_name = "schous"
}

provider "proxmox" {
  endpoint = "https://schous-proxmox.scienta.cloud"
}

resource "proxmox_virtual_environment_container" "v109" {
  node_name = local.node_name
  vm_id     = 109

  unprivileged = true

  tags = [
    "trygvis",
  ]

  initialization {
    hostname = "v109"

    user_account {
      password = random_password.password.result
    }

    ip_config {
      ipv6 {
        address = "2a11:6c7:1600:3101::109/64"
        gateway = "2a11:6c7:1600:3101::1"
      }
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  disk {
    datastore_id = "local-lvm"
  }

  operating_system {
    template_file_id = data.proxmox_file.alpine-3_23.id
    type             = "alpine"
  }

  network_interface {
    name     = "eth0"
    bridge   = "r64v1"
    firewall = true
  }

  network_interface {
    name     = "eth1"
    bridge   = "vmbr0"
    firewall = true
  }
}

data "proxmox_file" "alpine-3_23" {
  node_name    = local.node_name
  datastore_id = "local"
  content_type = "vztmpl"
  file_name    = "alpine-3.23-default_20260116_amd64.tar.xz"
}

resource "random_password" "password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

output "password" {
  value     = random_password.password.result
  sensitive = true
}
