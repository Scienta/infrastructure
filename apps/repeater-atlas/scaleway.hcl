generate "scaleway" {
  path      = "terragrunt-scaleway.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
# provider "scaleway" {
#   project_id = local.scaleway_project_id
#   organization_id = local.scaleway_organization_id
# }
# 
# locals {
#   scaleway_project_id = ""
#   scaleway_organization_id = ""
# }
EOF
}
