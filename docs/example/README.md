# 🧪 Example Configuration Files

This folder contains example configuration files used for bootstrapping or referencing when working with your homelab setup.

These files are **not meant to be committed with real values**. Instead, they act as templates to guide how your actual config files should look.

## Files

### `proxmox.auto.tfvars.example`

Terraform variable definitions used by the Proxmox provider during the initial bootstrap.

```hcl
proxmox = {
  name         = "pve-01"
  cluster_name = "homelab"
  endpoint     = "https://10.0.0.1:8006"
  cluster_ip   = "10.0.10.1"
  insecure     = true
  username     = "root@pam"
  password     = "secretpassword"
  api_token    = "root@pam!tofu=dfadf-dfa-ddsf3-bc32-fada41"
}
