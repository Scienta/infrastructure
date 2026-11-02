resource "scaleway_account_project" "project" {
  name = "sc-${var.name}"
}

output "organization_id" {
  value = scaleway_account_project.project.organization_id
}

output "project_id" {
  value = scaleway_account_project.project.id
}
