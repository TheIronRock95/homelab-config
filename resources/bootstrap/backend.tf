terraform {
  backend "local" {
    path = "/Users/wouter/personal/homelab-config/resources/state/talos.tfstate"  # Local path for the state file
  }
}
