include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  scaleway = read_terragrunt_config(find_in_parent_folders("scaleway.hcl"))
}

generate = local.scaleway.generate
