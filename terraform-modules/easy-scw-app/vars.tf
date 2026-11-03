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

# The port the application is listening on
variable "port" {
  type    = number
  default = 3000
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

variable "secret_environment_variables" {
  type      = map(string)
  default   = {}
  sensitive = true
}

variable "min_scale" {
  type    = number
  default = 0
}

variable "max_scale" {
  type    = number
  default = 1
}

# Request timeout in seconds
variable "timeout" {
  type    = number
  default = 600
}

# mvCPU
variable "cpu_limit" {
  type    = number
  default = 1024
}

# MB
variable "memory_limit" {
  type    = number
  default = 2048
}

# HTTP health check, e.g. { path = "/health", interval = "10s", failure_threshold = 18 }.
# null leaves the block out, which keeps Scaleway's default (an open port counts as ready).
variable "health_check" {
  type = object({
    path              = string
    interval          = string
    failure_threshold = number
  })
  default = null
}
