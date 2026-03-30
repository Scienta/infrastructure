locals {
  name           = "repeater-atlas"
  scienta_domain = "repeater-atlas"
  environment_variables = {
    "DB_CHECK" : "0"
  }
}

module "project" {
  source = "../../../terraform-modules/scw-project"
  name   = local.name
}

module "app" {
  source                = "../../../terraform-modules/easy-scw-app"
  name                  = local.name
  app_project_id        = module.project.project_id
  scienta_domain        = local.scienta_domain
  image_name            = "repeater-atlas:main"
  serverless_database   = true
  environment_variables = local.environment_variables
}
