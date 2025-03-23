# tofu/providers.tf
terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.5.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.70.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = "1.20.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox.endpoint

  # # TODO: use terraform variable or remove the line, and use PROXMOX_VE_USERNAME environment variable
  username = var.proxmox.username
  # # TODO: use terraform variable or remove the line, and use PROXMOX_VE_PASSWORD environment variable
  password = var.proxmox.password

  # because self-signed TLS certificate is in use
  insecure = var.proxmox.insecure
  # uncomment (unless on Windows...)
  # tmp_dir  = "/var/tmp"
  
  # api_token="root@pam!provider=2308c61e-2523-46f9-bdfa-13e4d9a55eb9"

  ssh {
    agent = true
    # TODO: uncomment and configure if using api_token instead of password
    # username = "root@pam"

    node {
      name    = var.proxmox.name
      address = var.proxmox.cluster_ip
    }
  }
}


provider "kubernetes" {
  host                   = module.talos.kube_config.kubernetes_client_configuration.host
  client_certificate     = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(module.talos.kube_config.kubernetes_client_configuration.ca_certificate)
}

provider "restapi" {
  uri                  = var.proxmox.endpoint
  insecure             = var.proxmox.insecure
  write_returns_object = true

  headers = {
    "Content-Type"  = "application/json"
    "Authorization" = "PVEAPIToken=${var.proxmox.api_token}"
  }
}

