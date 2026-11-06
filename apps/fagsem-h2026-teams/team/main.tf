# One Fagsem H2026 team: its own project, registry, container, database and
# read-only logs token, at https://fagsem-h2026-<slug>.scienta.cloud.

variable "slug" {
  type = string

  validation {
    # The harness is fagsem-h2026-harness.scienta.cloud
    condition     = var.slug != "harness"
    error_message = "\"harness\" can't be a team slug: that name and URL belong to the harness."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.slug))
    error_message = "A team slug is lower-case letters, digits and hyphens, so it works in project names and hostnames."
  }
}

variable "min_scale" {
  type = number
}

locals {
  name = "fagsem-h2026-${var.slug}"
}

module "project" {
  source = "../../../terraform-modules/scw-project"
  name   = local.name
}

module "app" {
  source         = "../../../terraform-modules/easy-scw-app"
  name           = local.name
  app_project_id = module.project.project_id
  scienta_domain = local.name

  # The team's deploy workflow pushes :<sha> and :latest
  image_name = "app:latest"
  port       = 8080

  min_scale = var.min_scale
  max_scale = 1

  # 3 minutes for Spring Boot and a database wake-up
  health_check = {
    path              = "/health"
    interval          = "10s"
    failure_threshold = 18
  }

  serverless_database = true

  make-registry-token = true
  make-logs-token     = true
}

output "team" {
  value = {
    access_key   = module.app.registry-access-key
    secret_key   = module.app.registry-secret-key
    registry_url = module.app.registry-url
    container_id = module.app.container-id
    url          = module.app.url
    logs_url     = module.app.logs-url
    logs_token   = module.app.logs-token
    # The scw CLI in deploy.yml won't run without an organisation ID.
    organization_id = module.project.organization_id
  }
  sensitive = true
}

output "registry" {
  value = {
    access_key   = module.app.registry-access-key
    secret_key   = module.app.registry-secret-key
    registry_url = module.app.registry-url
  }
  sensitive = true
}
