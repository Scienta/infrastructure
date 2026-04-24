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

resource "proxmox_virtual_environment_container" "v105" {
  node_name = local.node_name
  vm_id     = 105

  unprivileged = true

  tags = [
    "trygvis",
  ]

  #  ipv6 = {
  #  eth1 = "2a11:6c7:1600:3101::105"
  #  }


  initialization {
    hostname = "v105"

    ip_config {
      ipv6 {
        address = "2a11:6c7:1600:3101::105/64"
        gateway = "2a11:6c7:1600:3101::1"
      }
    }
  }


  disk {
    datastore_id = "local-lvm"
  }

  operating_system {
    template_file_id = "local:/vztmpl/alpine-3.23-default_20260116_amd64.tar.xz" # data.proxmox_file.alpine-3_23
    #    type             = "alpine"
  }

  network_interface {
    name     = "eth1"
    bridge   = "r64v1"
    firewall = true
  }
}

data "proxmox_file" "alpine-3_23" {
  node_name    = local.node_name
  datastore_id = "local"
  content_type = "vztmpl"
  # file_name    = "alpine-3.23-default_20260116_amd64.tar.xz"
  file_name = "rockylinux-10-default_20251001_amd64.tar.xz"
}
