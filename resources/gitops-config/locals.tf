locals {
  manifests = split("---", data.local_file.secret_yaml.content)
}