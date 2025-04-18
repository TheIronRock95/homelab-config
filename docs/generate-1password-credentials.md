# 🔐 How to Generate `onepassword-connect-credentials.json` and Token

This guide walks you through generating the credentials and token secrets required for deploying **1Password Connect** in your Kubernetes cluster.

---

## ✅ Prerequisites

To proceed, ensure you have:

- A [1Password](https://1password.com) Business or Teams account
- Admin access to the 1Password Developer Console
- A Kubernetes cluster (e.g. Talos, K3s, kubeadm)
- [1Password CLI (`op`)](https://developer.1password.com/docs/cli/get-started/) installed
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/) access

---

## 🧩 Step-by-Step Instructions

### 1. Log in to 1Password CLI

```bash
op signin
```

Follow the prompts to sign in and initialize your session.

---

### 2. Create a 1Password Connect App

1. Go to the [1Password Developer Console](https://developer.1password.com/keys/)
2. Click **Create new credential**
3. Select **Connect server** and follow the instructions
4. Download the generated JSON — this is your `onepassword-connect-credentials.json`

---

### 3. Retrieve Connect Token

The token is shown once when creating the credentials. Save it securely.

> If lost, you must regenerate the credentials.

---

## 🔐 Create Kubernetes Secrets

You need two secrets:

### ✅ 1. `onepassword-connect-credentials`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: onepassword-connect-credentials
  namespace: onepassword
type: Opaque
stringData:
  onepassword-connect-credentials.json: |-
    { "credentials": "YOUR-FULL-CREDENTIALS-JSON-CONTENT" }
```

### ✅ 2. `onepassword-connect-token-external-secret`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: onepassword-connect-token-external-secret
  namespace: external-secrets
type: Opaque
stringData:
  onepassword-connect-token: YOUR-RAW-CONNECT-TOKEN
```

> You may also use `kubectl create secret generic` with `--from-file` or `--from-literal` if preferred.

---

## 📦 Apply Secrets to the Cluster

```bash
kubectl apply -f secret.yaml
```

Or create them directly:

```bash
kubectl create secret generic onepassword-connect-credentials \
  --from-file=onepassword-connect-credentials.json=./onepassword-connect-credentials.json \
  -n onepassword

kubectl create secret generic onepassword-connect-token-external-secret \
  --from-literal=onepassword-connect-token=YOUR_TOKEN_HERE \
  -n external-secrets
```

---

## 📎 Notes

- The credentials file is **not base64-encoded** when stored via `stringData`. Kubernetes does this automatically.
- If storing the secret YAML in Git, use a tool like [SOPS](https://github.com/getsops/sops).
- These secrets are required before installing 1Password Connect via Helm.

---

## ✅ Next Step

Once secrets are in place, continue with the Helm installation:

```bash
helm install onepassword 1password-connect/connect \
  --namespace onepassword --create-namespace \
  --set connect.credentialsName=onepassword-connect-credentials \
  --set connect.credentialsKey=onepassword-connect-credentials.json
```

You’re now ready to integrate with External Secrets Operator!

