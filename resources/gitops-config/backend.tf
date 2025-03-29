terraform {
  backend "local" {
    path = "/Users/wouter/personal/homelab-config/resources/state/argocd.tfstate"  # Local path for the state file
  }
}
