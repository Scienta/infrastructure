locals {
  name           = "fagsem-h2026-01"
  scienta_domain = "fagsem-h2026-01"
  environment_variables = {
  }
}

module "project" {
  source = "../../terraform-modules/scw-project"
  name   = local.name
}

module "app" {
  source         = "../../terraform-modules/easy-scw-app"
  name           = "fagsem-h2026"
  app_project_id = module.project.project_id
  scienta_domain = local.scienta_domain

  # image_name            = "fagsem-h2026:main"
  # port                  = 8080

  image_registry        = "docker.io"
  image_name            = "nginxdemos/hello"
  port                  = 80

  serverless_database   = true
  environment_variables = local.environment_variables

  make-registry-token = true
}

output "scw-organization-id" {
  value     = module.project.organization_id
  sensitive = true
}

output "scw-project-id" {
  value     = module.project.project_id
  sensitive = true
}

output "registry-url" {
  value     = module.app.registry-url
  sensitive = true
}

output "registry-access-key" {
  value     = module.app.registry-access-key
  sensitive = true
}

output "registry-secret-key" {
  value     = module.app.registry-secret-key
  sensitive = true
}
