variable "kube_config_path" {
  description = "Pad naar het kubeconfig-bestand"
  type        = string
  default     = "~/.kube/config"
}

variable "secret_path" {
  description = "Pad naar het secret.yaml-bestand"
  type        = string
  default     = "$HOME/Downloads/secret.yaml"
}

variable "onepassword_version" {
  description = "Versie van de OnePassword chart"
  type        = string
}

variable "external_secrets_version" {
  description = "Versie van de External Secrets chart"
  type        = string
}

variable "namespaces" {
  default = ["onepassword", "external-secrets", "argocd"]
}