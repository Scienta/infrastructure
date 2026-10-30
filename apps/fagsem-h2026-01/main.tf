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
  name           = local.name
  app_project_id = module.project.project_id
  scienta_domain = local.scienta_domain
  #  image_name            = "fagsem-h2026-01:main"
  serverless_database   = true
  environment_variables = local.environment_variables

  image_name = "my-docker-image:latest"
  #  image_registry = "docker.io"
  port = 8080

  make-registry-token = true
}

output "registry-url" {
  value = module.app.registry-url
  sensitive = true
}

output "registry-token" {
  value = module.app.registry-token
  sensitive = true
}
