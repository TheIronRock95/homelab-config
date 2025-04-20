# 📚 Homelab Configuration Docs

This folder serves as a **wiki-style knowledge base** for configuring, managing, and maintaining your homelab environment.

It complements the OpenTofu-based infrastructure (`resources/bootstrap`) and GitOps configuration (`resources/gitops-config/`), offering human-readable documentation for:

- 🔧 Bootstrap and provisioning setup
- 🔐 Secrets and credentials management
- 📦 GitOps and ArgoCD configuration
- 🌐 Network and cluster layout
- ⚙️ Tooling and automation scripts
- 🧪 Example configurations

Feel free to expand this folder with Markdown docs, diagrams, notes, or usage guides to make your Homelab more maintainable and future-proof.

## Quick Links
- [1Password Connect](./generate-1password-credentials.md): Generate 1Password Connect credentials for External Secrets Operator.
- [Secrets Management](./secrets.md): Overview of secrets management using External Secrets Operator and 1Password Connect.
- [todo.md](./todo.md): List of tasks and ideas for future improvements.

## Structure

```bash
docs/
├── example/                                         
│   └── proxmox.auto.tfvars.example
├── generate-1password-credentials.md   
├── secrets.md                                      
├── Readme.md           
├── todo.md                                  
```
