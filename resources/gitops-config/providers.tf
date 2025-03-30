terraform {
  backend "local" {
    path = "/Users/wouter/personal/homelab-config/resources/state/argocd.tfstate"  # Local path for the state file
  }
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.5.0"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = ">=1.19.0"
    }
  }
}

provider "kubectl" {
  config_path = var.kube_config_path
}

provider "kubernetes" {
  config_path = var.kube_config_path
}

provider "helm" {
  kubernetes {
    config_path = var.kube_config_path
  }
}