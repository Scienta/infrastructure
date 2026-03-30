resource "scaleway_account_project" "project" {
  name = "sc-${var.name}"
}

output "project_id" {
  value = scaleway_account_project.project.id
}
