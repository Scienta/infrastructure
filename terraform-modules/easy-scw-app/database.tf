locals {
  serverless_database = var.serverless_database ? scaleway_sdb_sql_database.main["enabled"] : null
}

resource "scaleway_sdb_sql_database" "main" {
  for_each   = var.serverless_database ? { enabled = true } : {}
  project_id = var.app_project_id

  name    = var.name
  min_cpu = 0
  max_cpu = 1
}

resource "scaleway_iam_policy" "main_db_access" {
  for_each = var.serverless_database ? { enabled = true } : {}

  name           = "db_access"
  description    = "gives app access to serverless database in project"
  application_id = scaleway_iam_application.main.id
  rule {
    project_ids          = [var.app_project_id]
    permission_set_names = ["ServerlessSQLDatabaseReadWrite"]
  }
}

# output "database_connection_string" {
#   value = format("postgres://%s:%s@%s",
#     scaleway_iam_application.app.id,
#     scaleway_iam_api_key.api_key.secret_key,
#     trimprefix(scaleway_sdb_sql_database.database.endpoint, "postgres://"),
#   )
#   sensitive = true
# }
