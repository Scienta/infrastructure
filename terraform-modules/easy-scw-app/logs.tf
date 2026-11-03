# A read-only Cockpit token for the project's logs, for people and scripts
# that should read the app's logs and nothing else.

resource "scaleway_cockpit_token" "logs" {
  lifecycle {
    enabled = var.make-logs-token
  }

  project_id = var.app_project_id
  name       = format("%s-logs", var.name)

  scopes {
    query_logs = true
    # Both default to true
    write_logs    = false
    write_metrics = false
  }
}

data "scaleway_cockpit_source" "logs" {
  lifecycle {
    enabled = var.make-logs-token
  }

  project_id = var.app_project_id
  type       = "logs"
  origin     = "scaleway"
}

variable "make-logs-token" {
  type    = bool
  default = false
}

output "logs-url" {
  value = var.make-logs-token ? data.scaleway_cockpit_source.logs.url : null
}

output "logs-token" {
  value     = var.make-logs-token ? scaleway_cockpit_token.logs.secret_key : null
  sensitive = true
}
