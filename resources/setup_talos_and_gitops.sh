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

# Step 1: Prompt the user to choose between deleting or merging the kube config
echo "Do you want to (M)erge or (D)elete the existing kube config?"
echo "Press M for Merge, D for Delete:"
read -r choice

# Step 2: Navigate into the bootstrap directory
cd "$BOOTSTRAP_DIR"

# Step 3: Initialize OpenTofu in the bootstrap directory
echo "Initializing OpenTofu for resources/bootstrap"
tofu init  # Initialize OpenTofu with the local backend

# Step 4: Apply OpenTofu with auto-approve for resources/bootstrap
echo "Applying OpenTofu for resources/bootstrap"
tofu apply -auto-approve  # Apply the configuration

# Step 5: Ask user for action on kube config based on their earlier choice
if [[ "$choice" == "D" || "$choice" == "d" ]]; then
  echo "Deleting the existing kube config..."
  # Delete the existing kube config
  rm -f ~/.kube/config
  echo "Existing kube config deleted."

  echo "Copying kube-config.yaml to ~/.kube/config"
  # Copy the new kube config from the specified location to ~/.kube/config
  cp "$BOOTSTRAP_DIR/output/kube-config.yaml" ~/.kube/config

  # Alter the server URL in the new kube config
  echo "Updating the server URL in ~/.kube/config"
  sed -i '' '5s|https://10.0.10.210:6443|https://10.0.10.230:6443|' ~/.kube/config

elif [[ "$choice" == "M" || "$choice" == "m" ]]; then
  echo "Merging the new kube config with the existing one..."
  # If user chose merge, append the new config to the existing config file
  KUBE_CONFIG_PATH="$BOOTSTRAP_DIR/output/kube-config.yaml"
  if [ -f "$KUBE_CONFIG_PATH" ]; then
    # Ensure ~/.kube directory exists
    mkdir -p ~/.kube
    cat "$KUBE_CONFIG_PATH" >> ~/.kube/config
  else
    echo "Error: kube-config.yaml not found at $KUBE_CONFIG_PATH"
    exit 1
  fi

else
  echo "Invalid choice, please enter M for Merge or D for Delete."
  exit 1
fi

# Step 6: Navigate into the gitops-config directory
cd "$GITOPS_CONFIG_DIR"

# Step 7: Initialize OpenTofu in the gitops-config directory
echo "Initializing OpenTofu for resources/gitops-config"
tofu init  # Initialize OpenTofu with the local backend

# Step 8: Apply OpenTofu with auto-approve for resources/gitops-config
echo "Applying OpenTofu for resources/gitops-config"
tofu apply -auto-approve  # Apply the configuration

echo "✅ Script executed successfully!"
