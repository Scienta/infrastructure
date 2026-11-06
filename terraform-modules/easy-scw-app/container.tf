locals {
  registry = var.image_registry != null ? var.image_registry : scaleway_container_namespace.main.registry_endpoint
  image    = "${local.registry}/${var.image_name}"
}

locals {
  matches = local.serverless_database == null ? {} : regex("postgres://(?P<pghost>[^:]*):(?P<pgport>[0-9]*)/(?P<pgdatabase>[^?]*)", local.serverless_database.endpoint)

  database_env = local.serverless_database == null ? null : {
    "PGHOST"     = local.matches["pghost"]
    "PGPORT"     = local.matches["pgport"]
    "PGDATABASE" = local.matches["pgdatabase"]
    "PGUSER"     = scaleway_iam_application.main.id
    "PGPASSWORD" = scaleway_iam_api_key.main.secret_key
  }
}

resource "scaleway_container" "main" {
  name           = var.name
  description    = "Scienta Cloud '${var.name}'"
  tags           = ["scienta-cloud"]
  namespace_id   = scaleway_container_namespace.main.id
  registry_image = local.image
  port           = var.port
  cpu_limit      = var.cpu_limit
  memory_limit   = var.memory_limit
  min_scale      = var.min_scale
  max_scale      = var.max_scale
  timeout        = var.timeout
  privacy        = "public"
  http_option    = "redirected" # "enabled"
  protocol       = "http1"
  deploy         = true

  #  command = ["bash", "-c", "script.sh"]
  #  args    = ["some", "args"]

  environment_variables = merge({
    "DATABASE_URL" = local.serverless_database == null ? null : format("postgres://%s:%s@%s",
      scaleway_iam_application.main.id,
      scaleway_iam_api_key.main.secret_key,
      trimprefix(local.serverless_database.endpoint, "postgres://"),
    )
    "PGHOST"     = local.serverless_database == null ? null : local.database_env["PGHOST"]
    "PGUSER"     = local.serverless_database == null ? null : local.database_env["PGUSER"]
    "PGPASSWORD" = local.serverless_database == null ? null : local.database_env["PGPASSWORD"]
    "PGPORT"     = local.serverless_database == null ? null : local.database_env["PGPORT"]
    "PGDATABASE" = local.serverless_database == null ? null : local.database_env["PGDATABASE"]
  }, var.environment_variables)

  # null rather than {} when unused, so apps without secrets plan as before
  secret_environment_variables = length(var.secret_environment_variables) > 0 ? var.secret_environment_variables : null

  # Provider 2.70.1 has one probe for both start-up and liveness
  dynamic "health_check" {
    for_each = var.health_check == null ? [] : [var.health_check]
    content {
      http {
        path = health_check.value.path
      }
      interval          = health_check.value.interval
      failure_threshold = health_check.value.failure_threshold
    }
  }
}

output "container-id" {
  # The resource ID is "<region>/<uuid>"; scw and the API want the bare UUID
  value = regex("[^/]+$", scaleway_container.main.id)
}

output "url" {
  value = var.scienta_domain != null ? "https://${var.scienta_domain}.scienta.cloud" : "https://${scaleway_container.main.domain_name}"
}
