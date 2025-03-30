#!/bin/bash

# Exit on error
set -e

# Get the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define the base path for the homelab-config repo
BASE_DIR="$(dirname "$SCRIPT_DIR")"  # This is the homelab-config repo root

# Define the paths to resources, bootstrap, state, and gitops-config
RESOURCES_DIR="$BASE_DIR/resources"
BOOTSTRAP_DIR="$RESOURCES_DIR/bootstrap"
STATE_DIR="$RESOURCES_DIR/state"
GITOPS_CONFIG_DIR="$RESOURCES_DIR/gitops-config"

# Step 1: Clear the kube config file content (but leave the file)
echo "Clearing the kube config contents..."
if [ -f ~/.kube/config ]; then
  > ~/.kube/config  # Clear the content of the kube config file
  echo "Kube config contents cleared."
else
  echo "No kube config found to clear."
fi

# Step 2: Destroy resources in bootstrap using tofu
echo "Destroying resources in bootstrap..."
cd "$BOOTSTRAP_DIR"
tofu destroy -auto-approve
echo "Resources in bootstrap destroyed."

# Step 3: Check if the cluster is still alive by checking the kube config
if [ -f ~/.kube/config ] && grep -q "server: https://10.0.10.230:6443" ~/.kube/config; then
  # Destroy resources in gitops-config using tofu if the cluster is still up
  echo "Destroying resources in gitops-config..."
  cd "$GITOPS_CONFIG_DIR"
  tofu destroy -auto-approve
  echo "Resources in gitops-config destroyed."
else
  echo "Cluster is destroyed, skipping GitOps destruction."
fi

# Step 4: Delete state files (if you want to clean up the state as well)
echo "Deleting state files..."
rm -f "$STATE_DIR/terraform.tfstate"  # Bootstrap state
rm -f "$STATE_DIR/gitops-config-terraform.tfstate"  # GitOps config state
echo "State files deleted."

# Step 5: Delete .terraform directories and .terraform.lock.hcl files
echo "Cleaning up .terraform directories and lock files..."
rm -rf "$BOOTSTRAP_DIR/.terraform" "$GITOPS_CONFIG_DIR/.terraform"
rm -f "$BOOTSTRAP_DIR/.terraform.lock.hcl" "$GITOPS_CONFIG_DIR/.terraform.lock.hcl"
echo ".terraform directories and lock files removed."

echo "✅ All resources and configuration files have been deleted successfully."
