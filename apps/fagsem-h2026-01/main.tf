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
  source                = "../../terraform-modules/easy-scw-app"
  name                  = local.name
  app_project_id        = module.project.project_id
  scienta_domain        = local.scienta_domain
  image_name            = "fagsem-h2026-01:main"
  serverless_database   = true
  environment_variables = local.environment_variables
}
