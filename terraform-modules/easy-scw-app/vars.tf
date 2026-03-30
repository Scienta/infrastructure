variable "name" {
  type = string
}

variable "app_project_id" {
  type = string
}

variable "scienta_domain" {
  type    = string
  default = null
}

# If set, an external registry will be used. If not set an internal registry
# will be created
variable "image_registry" {
  type    = string
  default = null
}

variable "image_name" {
  type = string
}

variable "serverless_database" {
  type    = bool
  default = false
}

variable "environment_variables" {
  type    = map(any)
  default = {}
}
