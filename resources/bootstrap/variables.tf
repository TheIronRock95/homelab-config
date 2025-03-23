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
