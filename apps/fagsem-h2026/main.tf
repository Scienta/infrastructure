# Fagsem H2026: the organisers' project with the game harness, at
# https://fagsem-h2026-harness.scienta.cloud. The teams are in
# ../fagsem-h2026-teams.
#
# Bring-up runs in two phases, because the container can't start before an
# image is in the registry:
#
#   1. terragrunt run -- apply -exclude=module.app.scaleway_container.main
#      creates the project, registry, push key, database and logs token.
#      Then push the harness image to registry-url as harness:latest.
#   2. terragrunt apply
#      creates the container, then the CNAME and the custom domain.
#
# plan, apply and destroy need GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in
# the environment (see terragrunt.hcl).
# Organisers read the secrets with `terragrunt output -raw <name>`.

terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
  }
}

locals {
  name           = "fagsem-h2026"
  scienta_domain = "fagsem-h2026-harness"

  environment_variables = {
    "HARNESS_PORT" = "8080"
    # 4.0 for the dry run (240 ticks in 60 minutes), 1.0 for the game
    "FAGDAG_TIME_SCALE" = "1.0"
  }

  secret_environment_variables = {
    "FAGDAG_EVENT_SEED"         = random_password.event_seed.result
    "FAGDAG_TOKEN_SECRET"       = random_password.token_secret.result
    "FAGDAG_ADMIN_TOKEN_SECRET" = random_password.admin_token_secret.result
    "GOOGLE_CLIENT_ID"          = var.google_client_id
    "GOOGLE_CLIENT_SECRET"      = var.google_client_secret
  }
}

variable "google_client_id" {
  type      = string
  sensitive = true

  validation {
    condition     = length(var.google_client_id) > 0
    error_message = "Set GOOGLE_CLIENT_ID in the environment."
  }
}

variable "google_client_secret" {
  type      = string
  sensitive = true

  validation {
    condition     = length(var.google_client_secret) > 0
    error_message = "Set GOOGLE_CLIENT_SECRET in the environment."
  }
}

resource "random_password" "event_seed" {
  length  = 32
  special = false
}

resource "random_password" "token_secret" {
  length  = 48
  special = false
}

resource "random_password" "admin_token_secret" {
  length  = 48
  special = false
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

  image_name = "harness:latest"
  port       = 8080

  # Always on: the harness runs the game clock. SSE streams are cut at the
  # timeout, and the browsers reconnect.
  min_scale = 1
  max_scale = 1
  timeout   = 3600

  # 3 minutes for Spring Boot and a database wake-up
  health_check = {
    path              = "/health"
    interval          = "10s"
    failure_threshold = 18
  }

  serverless_database          = true
  environment_variables        = local.environment_variables
  secret_environment_variables = local.secret_environment_variables

  make-registry-token = true
  make-logs-token     = true
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

output "container-id" {
  value = module.app.container-id
}

output "url" {
  value = module.app.url
}

output "logs-url" {
  value     = module.app.logs-url
  sensitive = true
}

output "logs-token" {
  value     = module.app.logs-token
  sensitive = true
}

# For the organisers' pg_dump backups
output "database-env" {
  value     = module.app.database-env
  sensitive = true
}

output "event-seed" {
  value     = random_password.event_seed.result
  sensitive = true
}

output "token-secret" {
  value     = random_password.token_secret.result
  sensitive = true
}

output "admin-token-secret" {
  value     = random_password.admin_token_secret.result
  sensitive = true
}
