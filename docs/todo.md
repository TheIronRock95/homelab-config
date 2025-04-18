# 🗂 Suggested Documentation Structure

## 🔧 1. `infrastructure.md`

**Explain how you provision your base infrastructure:**
- Proxmox setup (via `main.tf`)
- Talos node creation
- Networking assumptions (e.g. MetalLB, cluster VIPs)
- References to `bootstrap/` and `tofu/` folders
- Mention example `.auto.tfvars` layout

📂 **Examples:**
- `example/proxmox.auto.tfvars.example`
- Diagram of node layout (optional: with Mermaid!)

---

## 🚀 2. `bootstrap.md`

**Describe what happens during initial cluster bootstrap:**
- Talos machine config flow
- Kubeconfig generation and storage
- Any DNS/LoadBalancer setup
- Setup script reference (`setup_talos_and_gitops.sh`)

📂 **Examples:**
- Sample Talos config snippet
- `secrets/clusterconfig.sample.yaml`

---

## 🔄 3. `gitops.md`

**Explain the GitOps flow:**
- Argo CD setup and how apps are bootstrapped
- Structure of your `resources/gitops-config/` repo
- How Argo CD apps are structured (e.g. `apps/project/app.yaml`)
- Sync waves (if applicable)

📂 **Examples:**
- `apps/infra/argocd.yaml`
- `projects/argocd-project.yaml`

---

## 🔐 4. `secrets.md` (✅ Done)

---

## 📡 5. `networking.md`

**Document:**
- Cluster ingress (e.g. Traefik/IngressNginx)
- MetalLB setup (if used)
- DNS configuration (e.g. `*.homelab.local` or Cloudflare if external)
- External access to ArgoCD, 1Password UI, etc.

📂 **Examples:**
- `ingress.yaml`
- External access secret

---

## 🛠️ 6. `scripts.md`

**Describe each script in the root:**
- `setup_talos_and_gitops.sh`
- `delete_all_resources.sh`
- Any helper or debugging utilities

---

## 🧪 7. `troubleshooting.md`

**Tips for common issues:**
- Argo CD not syncing?
- Secrets not appearing?
- Talos node stuck in maintenance?
- Helm chart fails?

---

## 📑 8. `README.md` (✅ Done)

