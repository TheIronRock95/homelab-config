# tofu/variables.tf
variable "proxmox" {
  type = object({
    name         = string
    cluster_name = string
    endpoint     = string
    cluster_ip   = string
    insecure     = bool
    username     = string
    password     = string
    api_token    = string
  })
  sensitive = true
}

onepassword_version      = "1.17.0"
external_secrets_version = "0.14.2"
