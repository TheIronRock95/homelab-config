# 🔐 Secrets Management with External Secrets Operator & 1Password Connect

This guide explains how secrets are managed in the homelab using **External Secrets Operator (ESO)** integrated with **1Password Connect**. Secrets such as GitHub credentials for Argo CD (repository sync and SSO login) are securely pulled from 1Password vaults into Kubernetes.

---

## 📦 Components

### 🔁 External Secrets Operator (ESO)
- Syncs secrets from external providers into Kubernetes `Secret` resources.
- GitHub: https://github.com/external-secrets/external-secrets

### 🧩 1Password Connect
- A lightweight service deployed in-cluster that allows ESO to securely retrieve secrets from your 1Password vaults.
- Docs: https://developer.1password.com/docs/connect/

---

## ✅ Prerequisites

To use this setup you need:

- A running Kubernetes cluster (e.g. Talos, k3s, kubeadm, etc.)
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/)
- [`helm`](https://helm.sh/docs/intro/install/)
- Valid 1Password Connect credentials file ([`onepassword-credentials.json`](./generate-1password-credentials.md))
- Optional: GitHub App configured for Argo CD repo access and SSO

---

## 🚀 Automated Setup Options

There are two ways to automate this setup:

### 1. `setup_talos_and_gitops.sh` (for Talos clusters)
Located at the root of the repo, this script:

- Provisions Talos infrastructure (via Terraform/OpenTofu)
- Installs 1Password Connect & External Secrets via Helm
- Applies the necessary `Secret` and `ExternalSecret` resources

This is the easiest way to bootstrap a fully GitOps-managed Talos homelab.

### 2. `main.tf` (for generic Kubernetes clusters)
If you're running another Kubernetes distribution, you can use the `main.tf` in `gitops-config/`:

- Defines Helm releases for ESO and 1Password Connect
- Applies Kubernetes secrets and manifests via OpenTofu

Run it with:
```bash
cd resources/gitops-config
opentofu init
opentofu apply
```

---

## 📁 Secrets Overview

All secrets are declared using `ExternalSecret` custom resources in:

```bash
gitops-config/input-files/
├── onepassword-connect-credentials.yaml     # OnePassword Connect credential
├── github-private-repo-creds.yaml           # Argo CD GitHub repo credentials
├── github-client-secret.yaml                # GitHub OAuth app secret for Argo CD SSO
├── secret.yaml                              # Base Kubernetes Secret for Connect
```

---

## 🛠 Setup Process (Manual Flow)

The manual setup process follows these steps:

### 1. Apply `secret.yaml`
This creates the Kubernetes Secret needed to run the 1Password Connect server.

```bash
kubectl apply -f gitops-config/input-files/secret.yaml
```

#### 🧪 Example: `secret.yaml`
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: onepassword-connect-credentials
  namespace: onepassword
  labels:
    app.kubernetes.io/name: onepassword-connect
    app.kubernetes.io/component: credentials
    app.kubernetes.io/managed-by: helm
    app.kubernetes.io/part-of: 1password
type: Opaque
stringData:
  onepassword-connect-credentials.json: |-
    { "credentials": "REPLACE-WITH-BASE64-OR-RAW-JSON" }
---
apiVersion: v1
kind: Secret
metadata:
  name: onepassword-connect-token-external-secret
  namespace: external-secrets
type: Opaque
stringData:
  onepassword-connect-token: "REPLACE-WITH-YOUR-CONNECT-TOKEN"
```

### 2. Install ESO & 1Password Connect with Helm
Install both services using Helm:

```bash
# Add Helm repos
helm repo add 1password-connect https://1password.github.io/connect-helm-charts
helm repo add external-secrets-operator https://charts.external-secrets.io
helm repo update

# Install 1Password Connect
helm install onepassword 1password-connect/connect \
  --namespace onepassword --create-namespace \
  --set connect.credentialsName=onepassword-connect-credentials \
  --set connect.credentialsKey=onepassword-connect-credentials.json

# Install External Secrets Operator
helm install external-secrets external-secrets-operator/external-secrets \
  --namespace external-secrets --create-namespace \
  --set installCRDs=true
```

### 3. Apply ExternalSecrets Definitions
Once both services are running, apply the ExternalSecret resources:

```bash
kubectl apply -f gitops-config/input-files/github-private-repo-creds.yaml
kubectl apply -f gitops-config/input-files/github-client-secret.yaml
kubectl apply -f gitops-config/input-files/onepassword-connect-credentials.yaml
```

---

## 📄 Example ExternalSecrets

### GitHub Private Repo Credentials for Argo CD
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: github-private-repo-creds
  namespace: argocd
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: onepassword-connect
  target:
    name: github-private-repo-creds
    creationPolicy: Owner
    template:
      type: Opaque
      metadata:
        labels:
          argocd.argoproj.io/secret-type: repository
      data:
        type: git
        url: https://github.com/example/homelab-config
        githubAppID: "123456"
        githubAppInstallationID: "7891011"
        githubAppPrivateKey: '{{ .argoPrivateKey }}'
  data:
    - secretKey: argoPrivateKey
      remoteRef:
        key: github-argo-app
        property: private-key.pem
```

### GitHub OAuth Client Secret for Argo CD SSO
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: github-client-secret
  namespace: argocd
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: onepassword-connect
  target:
    name: github-client-secret
    creationPolicy: Owner
    template:
      type: Opaque
      metadata:
        labels:
          argocd.argoproj.io/secret-type: argocd
          app.kubernetes.io/part-of: argocd
      data:
        dex.github.clientSecret: '{{ .clientSecret }}'
  data:
    - secretKey: clientSecret
      remoteRef:
        key: github-client-secrets
        property: password
```

### 1Password Connect Secret
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: onepassword-connect-credentials
  namespace: onepassword
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: onepassword-connect
  target:
    name: onepassword-connect-credentials
    creationPolicy: Owner
    template:
      type: Opaque
      data:
        onepassword-connect-credentials.json: '{{ .credentials }}'
  data:
    - secretKey: credentials
      remoteRef:
        key: onepassword-connect-credentials.json
        property: password
```

---

## 🧪 Test Your Setup
After deploying the `ExternalSecret` resources:

```bash
kubectl get externalsecret -A
kubectl get secret -n argocd github-private-repo-creds -o yaml
```

You should see a populated Kubernetes Secret with decoded values (e.g. private keys, OAuth secrets).

---

## ✅ Summary
- Secrets are securely synced from 1Password via External Secrets Operator.
- GitHub credentials are used by Argo CD for repo sync + SSO.
- Manual setup flow: apply base secret → install Helm charts → apply ExternalSecrets.
- All manifests are stored in `gitops-config/input-files/` and handled declaratively.

Keep secrets out of your Git repo and rotate them in 1Password without changing Kubernetes directly.

