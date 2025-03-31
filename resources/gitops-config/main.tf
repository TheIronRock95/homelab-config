data "local_file" "secret_yaml" {
  filename = var.secret_path
}

### Step-by-Step Namespace Creation with Validation
resource "kubernetes_namespace" "namespaces" {
  for_each = toset(var.namespaces)

  metadata {
    name = each.value
  }
}

resource "kubectl_manifest" "apply_secrets" {
  count     = length(local.manifests)
  yaml_body = local.manifests[count.index]

  depends_on = [
    kubernetes_namespace.namespaces
  ]
}

### Install 1Password Connector
resource "helm_release" "onepassword" {
  name       = "onepassword"
  repository = "https://1password.github.io/connect-helm-charts"
  chart      = "connect"
  namespace  = kubernetes_namespace.namespaces["onepassword"].metadata[0].name
  version    = var.onepassword_version
  values     = [file("operators/onepassword-connect/values.yaml")]

  depends_on = [
    kubectl_manifest.apply_secrets
  ]
}

### Install External Secrets Operator
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = kubernetes_namespace.namespaces["external-secrets"].metadata[0].name
  version    = var.external_secrets_version
  values     = [file("operators/external-secrets/values.yaml")]

  set {
    name  = "includeCRDs"
    value = true
  }

  depends_on = [
    helm_release.onepassword
  ]
}

resource "time_sleep" "wait_for_webhook" {
  depends_on = [helm_release.external_secrets]

  create_duration = "30s" # Adjust based on readiness time
} 

# Apply ClusterSecretStore
resource "kubectl_manifest" "cluster_secret_store" {
  yaml_body = file("operators/external-secrets/templates/cluster-secret-store.yaml")

  depends_on = [
    helm_release.external_secrets,
    time_sleep.wait_for_webhook
  ]
}

# Wait for ClusterSecretStore to be ready
resource "time_sleep" "wait_for_cluster_secret_store" {
  depends_on = [kubectl_manifest.cluster_secret_store]

  create_duration = "15s" # Adjust based on readiness time
}

### Install ArgoCD
resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  namespace  = kubernetes_namespace.namespaces["argocd"].metadata[0].name
  chart      = "argo-cd"
  version    = "7.8.13"
  values     = [file("./operators/argo-cd/values.yaml")]
  depends_on = [
    time_sleep.wait_for_cluster_secret_store,
    kubectl_manifest.cluster_secret_store
  ]
}

# ### Deploy Root App
resource "null_resource" "deploy_root_app" {
  provisioner "local-exec" {
    command = "helm template ./sync-app | kubectl apply -f -"
  }

  triggers = {
    argo_cd_release_id = helm_release.argo_cd.id
  }

  depends_on = [
    helm_release.argo_cd
  ]
}

