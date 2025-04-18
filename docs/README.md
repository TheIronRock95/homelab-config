# 📚 Homelab Configuration Docs

This folder serves as a **wiki-style knowledge base** for configuring, managing, and maintaining your homelab environment.

It complements the OpenTofu-based infrastructure (`resources/`) and GitOps configuration (`resources/gitops-config/`), offering human-readable documentation for:

- 🔧 Bootstrap and provisioning setup
- 🔐 Secrets and credentials management
- 📦 GitOps and ArgoCD configuration
- 🌐 Network and cluster layout
- ⚙️ Tooling and automation scripts
- 🧪 Example configurations

Feel free to expand this folder with Markdown docs, diagrams, notes, or usage guides to make your Homelab more maintainable and future-proof.

## Structure

```bash
docs/
├── example/                   # Example configuration files
│   └── proxmox.auto.tfvars.example
├── secrets.md                 # How secrets are managed (1Password + External Secrets)
├── Readme.md                  # This file
