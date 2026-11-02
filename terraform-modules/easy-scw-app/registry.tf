resource "scaleway_container_namespace" "main" {
  project_id = var.app_project_id

  name        = var.name
  description = "Scienta Cloud '${var.name}'"
}

output "registry-url" {
  value = scaleway_container_namespace.main.registry_endpoint
}

resource "scaleway_iam_application" "registry" {
  lifecycle {
    enabled = var.make-registry-token
  }

  name = format("%s-registry", var.name)
}

resource "scaleway_iam_api_key" "registry" {
  application_id = scaleway_iam_application.registry.id

  lifecycle {
    enabled = var.make-registry-token
  }
}

resource "scaleway_iam_policy" "registry" {
  lifecycle {
    enabled = var.make-registry-token
  }

  name           = format("%s-registry", var.name)
  description    = "Gives registry token access to push to registry"
  application_id = scaleway_iam_application.registry.id
  rule {
    project_ids          = [var.app_project_id]
    permission_set_names = ["ContainerRegistryFullAccess"]
  }
}


variable "make-registry-token" {
  type    = bool
  default = false
}

output "registry-access-key" {
  value     = var.make-registry-token ? scaleway_iam_api_key.registry.access_key : null
  sensitive = true
}

output "registry-secret-key" {
  value     = var.make-registry-token ? scaleway_iam_api_key.registry.secret_key : null
  sensitive = true
}
