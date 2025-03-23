### Step-by-Step Namespace Creation with Validation
resource "kubernetes_namespace" "namespaces" {
  for_each = toset(var.namespaces)

  metadata {
    name = each.value
  }
}

resource "null_resource" "validate_namespaces" {
  for_each = toset(var.namespaces)

  provisioner "local-exec" {
    command = <<EOT
until kubectl get namespace ${each.value} -o jsonpath='{.status.phase}' | grep -q "Active"; do
  echo "Waiting for namespace ${each.value} to become active..."
  sleep 5
done
EOT
  }

  depends_on = [kubernetes_namespace.namespaces]
}

### Apply Secret and Validate
resource "null_resource" "apply_secret" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${var.secret_path}"
  }

  depends_on = [null_resource.validate_namespaces]
}

resource "time_sleep" "wait_for_secret" {
  create_duration = "40s"

  depends_on = [
    null_resource.apply_secret
  ]
}

### Helm Dependency Build for ArgoCD
resource "null_resource" "helm_dependency_argo" {
  provisioner "local-exec" {
    command = "helm dependency build operators/argo-cd"
  }

  depends_on = [
    time_sleep.wait_for_secret
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
    null_resource.helm_dependency_argo
  ]
}

### Validate 1Password Deployment
resource "null_resource" "validate_onepassword" {
  provisioner "local-exec" {
    command = <<EOT
until kubectl rollout status deployment/onepassword-connect -n onepassword --timeout=300s; do
  echo "Waiting for 1Password deployment to be ready..."
  sleep 5
done
EOT
  }

  depends_on = [
    helm_release.onepassword
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
    null_resource.validate_onepassword
  ]
}

resource "null_resource" "wait_for_webhook" {
  provisioner "local-exec" {
    command = "sleep 30"
  }

  depends_on = [
    helm_release.external_secrets
  ]
}

### Apply ClusterSecretStore and Validate
resource "null_resource" "apply_cluster_secret_store" {
  provisioner "local-exec" {
    command = <<EOT
kubectl apply -f operators/external-secrets/templates/cluster-secret-store.yaml
sleep 10
until kubectl get ClusterSecretStore onepassword-connect -n external-secrets -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; do
  echo "Waiting for ClusterSecretStore to be ready..."
  sleep 5
done
EOT
  }

  depends_on = [
    null_resource.wait_for_webhook
  ]
}

### Apply Additional Secrets
resource "null_resource" "apply_additional_secrets" {
  provisioner "local-exec" {
    command = <<EOT
kubectl apply -f operators/external-secrets/templates/github-client-secret.yaml \
              -f operators/external-secrets/templates/github-private-repo-creds.yaml \
              -f operators/external-secrets/templates/onepassword-connect-credentials.yaml
EOT
  }

  depends_on = [
    null_resource.apply_cluster_secret_store
  ]
}

### Install ArgoCD
resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  chart      = "operators/argo-cd/"
  namespace  = kubernetes_namespace.namespaces["argocd"].metadata[0].name

  depends_on = [
    null_resource.apply_additional_secrets
  ]
}

### Deploy Root App
resource "null_resource" "deploy_root_app" {
  provisioner "local-exec" {
    command = "helm template ./sync-app | kubectl apply -f -"
  }

  depends_on = [
    helm_release.argo_cd
  ]
}

resource "null_resource" "output" {
  provisioner "local-exec" {
    command = "echo '✅ Deployments completed successfully.'"
  }

  depends_on = [
    null_resource.deploy_root_app
  ]
}
