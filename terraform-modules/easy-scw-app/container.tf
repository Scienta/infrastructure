resource "scaleway_container_namespace" "main" {
  project_id = var.app_project_id

  name        = var.name
  description = "Scienta Cloud '${var.name}'"
}

locals {
  registry = var.image_registry != null ? var.image_registry : scaleway_container_namespace.main.registry_endpoint
  image    = "${local.registry}/${var.image_name}"
}

locals {
  matches = local.serverless_database == null ? {} : regex("postgres://(?P<pghost>[^:]*):(?P<pgport>[0-9]*)/(?P<pgdatabase>[^?]*)", local.serverless_database.endpoint)
}

resource "scaleway_container" "main" {
  name           = var.name
  description    = "Scienta Cloud '${var.name}'"
  tags           = ["scienta-cloud"]
  namespace_id   = scaleway_container_namespace.main.id
  registry_image = local.image
  port           = 3000
  cpu_limit      = 1024
  memory_limit   = 2048
  min_scale      = 0
  max_scale      = 1
  timeout        = 600
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
    "PGHOST"     = local.serverless_database == null ? null : local.matches["pghost"]
    "PGUSER"     = local.serverless_database == null ? null : scaleway_iam_application.main.id
    "PGPASSWORD" = local.serverless_database == null ? null : scaleway_iam_api_key.main.secret_key
    "PGPORT"     = local.serverless_database == null ? null : local.matches["pgport"]
    "PGDATABASE" = local.serverless_database == null ? null : local.matches["pgdatabase"]
  }, var.environment_variables)
  #  secret_environment_variables = {
  #    "key" = "secret"
  #  }
}
