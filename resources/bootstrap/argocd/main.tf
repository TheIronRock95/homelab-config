### Namespaces aanmaken via for_each met validatie
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
  echo "Wachten op namespace ${each.value}..."
  sleep 5
done
EOT
  }

  depends_on = [kubernetes_namespace.namespaces]
}

### Secret toepassen (met kubectl apply in plaats van yamldecode)
resource "null_resource" "apply_secret" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${var.secret_path}"
  }

  depends_on = [null_resource.validate_namespaces]
}

### Helm dependency build voor ArgoCD
resource "null_resource" "helm_dependency_argo" {
  provisioner "local-exec" {
    command = "helm dependency build charts/argo-cd"
  }
  depends_on = [null_resource.validate_namespaces]
}

### 1Password Connector installeren
resource "helm_release" "onepassword" {
  name       = "onepassword"
  repository = "https://1password.github.io/connect-helm-charts"
  chart      = "connect"
  namespace  = kubernetes_namespace.namespaces["onepassword"].metadata[0].name
  version    = var.onepassword_version
  values     = [file("charts/onepassword-connect/values.yaml")]
  depends_on = [null_resource.apply_secret]
}

### Validatie: Wachten tot 1Password Deployment gereed is
resource "null_resource" "validate_onepassword" {
  provisioner "local-exec" {
    command = <<EOT
until kubectl rollout status deployment/onepassword-connect -n onepassword --timeout=300s; do
  echo "Wachten tot 1Password deployment gereed is..."
  sleep 5
done
EOT
  }

  depends_on = [helm_release.onepassword]
}

### External Secrets Operator installeren
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = kubernetes_namespace.namespaces["external-secrets"].metadata[0].name
  version    = var.external_secrets_version
  values     = [file("charts/external-secrets/values.yaml")]

  set {
    name  = "includeCRDs"
    value = true
  }
  depends_on = [null_resource.validate_onepassword]
}

### Wachten op de webhook
resource "null_resource" "wait_for_webhook" {
  depends_on = [helm_release.external_secrets]

  provisioner "local-exec" {
    command = "sleep 30"
  }
}

### ClusterSecretStore toepassen en validatie uitvoeren
resource "null_resource" "apply_cluster_secret_store" {
  depends_on = [null_resource.wait_for_webhook]

  provisioner "local-exec" {
    command = <<EOT
kubectl apply -f charts/external-secrets/templates/cluster-secret-store.yaml
sleep 10
until kubectl get ClusterSecretStore onepassword-connect -n external-secrets -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; do
  echo "Wachten tot ClusterSecretStore gereed is..."
  sleep 5
done
EOT
  }
}

### Extra secrets toepassen
resource "null_resource" "apply_additional_secrets" {
  depends_on = [null_resource.apply_cluster_secret_store]

  provisioner "local-exec" {
    command = <<EOT
kubectl apply -f charts/external-secrets/templates/github-client-secret.yaml \
              -f charts/external-secrets/templates/github-private-repo-creds.yaml \
              -f charts/external-secrets/templates/onepassword-connect-credentials.yaml
EOT
  }
}

### ArgoCD installeren
resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  chart      = "charts/argo-cd/"
  namespace  = kubernetes_namespace.namespaces["argocd"].metadata[0].name
  depends_on = [null_resource.helm_dependency_argo]
}

### Root-app toepassen vanuit de juiste map
resource "null_resource" "deploy_root_app" {
  depends_on = [helm_release.argo_cd]

  provisioner "local-exec" {
    command = "helm template ./charts/root-app | kubectl apply -f -"
  }
}

resource "null_resource" "output" {
  provisioner "local-exec" {
    command = "echo '✅ Deployments voltooid.'"
  }
}