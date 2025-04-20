# 🏡 My Homelab Configuration

This repository contains the complete Infrastructure-as-Code (IaC) and GitOps configuration for my homelab environment, powered by **Proxmox**, **Talos Linux**, **Argo CD**, and **OpenTofu**.

---

## 🧭 Project Structure Overview

This setup is divided into two major components:

- **Infrastructure Bootstrap** (`resources/bootstrap`)  
  Provision Talos VMs on Proxmox, CSI plugin config, Talos machine/image setup, and OpenTofu orchestration.
  
- **GitOps Configuration** (`resources/gitops-config`)  
  Cluster apps and services managed via Argo CD, including operators, secrets, and Helm-based application installs.

---

## ⚙️ Setup Instructions

### ✅ Prerequisites

Before running the setup, make sure these tools are installed:

- [`talosctl`](https://www.talos.dev/docs/latest/introduction/what-is-talos/)
- [`kubectl`](https://kubernetes.io/)
- [`OpenTofu`](https://opentofu.org/)
- [`argocd`](https://argo-cd.readthedocs.io/)
- [`proxmox`](https://www.proxmox.com/en/)

---

### 🚀 Bootstrap Infrastructure & GitOps

Run the following to fully deploy Talos, bootstrap the cluster, and install Argo CD:

```bash
./setup_talos_and_gitops.sh
```

What it does:

1. Provisions infrastructure using Terraform (VMs on Proxmox)
2. Generates and applies Talos configs (`machine-config`, `image`)
3. Installs Talos cluster components (e.g. Cilium)
4. Deploys Argo CD and syncs the GitOps config

> 🔐 You must configure [`proxmox.auto.tfvars`](docs/example/proxmox.auto.tfvars.example) with your Proxmox credentials.

---

### 🩹 Teardown / Cleanup

To remove everything:

```bash
./delete_all_resources.sh
```

This deletes:

- All Kubernetes resources
- Opentofu-managed infrastructure

---

## 🗂️ Directory Structure

```plaintext
resources/
|
|
├── docs/
│   ├── example/
|
├── bootstrap/
│   ├── output/                        
│   ├── proxmox-csi-plugin/          
│   ├── talos/
│   │   ├── image/
│   │   ├── inline-manifests/
│   │   └── machine-config/
│   └── other files                         # main.tf, variables.tf, etc.
│
├── gitops-config/
│   ├── input-files/                        
│   ├── operators/                          
│   │   ├── argo-cd/
│   │   |   ├── templates/
│   │   ├── cert-manager/
│   │   |   ├── templates/
│   │   ├── cilium/
│   │   |   ├── templates/
│   │   ├── external-dns/
│   │   |   ├── templates/
│   │   └── external-secrets/
│   │       ├── templates/
│   ├── sync-app/
│   │   ├── templates/
│   └── other files                         # main.tf, variables.tf, etc.
│
├── state/
│
│── setup_talos_and_gitops.sh
│── delete_all_resources.sh
├── LICENSE
├── .gitignore
├── renovate.json
└── README.md
```

---

## 🔐 Secrets Management

Secrets like GitHub tokens and 1Password credentials are stored in:

- `resources/gitops-config/input-files/`  
  > These are **not committed** and should be generated manually or via automation prior to running GitOps sync.

---

## 📆 GitOps-Managed Applications

Deployed and managed through Argo CD:

- `argocd` — GitOps CD tool
- `cert-manager` — TLS management
- `cilium` — CNI for Talos
- `external-dns` — Auto-DNS management
- `external-secrets` — Secrets from vaults
- `sync-app` — Root Argo CD app syncing the rest

---
## 📓 Docs
- [`docs/`](docs/README.md) — Wiki-style knowledge base for configuring, managing, and maintaining your homelab environment.

---

## 🤝 Contributing

Pull requests and issue reports are welcome!  
Please feel free to open an issue or submit a PR if you have ideas to improve this setup.

---

## 📄 License

This project is licensed under the [MIT License](./LICENSE).