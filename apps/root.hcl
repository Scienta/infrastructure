remote_state {
  backend  = "s3"
  generate = {
    path      = "terragrunt-backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket                      = "scienta-cloud-state-a86097d6-29e1-11f1-a8c1-d45d64079ca5"
    key                         = "apps/${path_relative_to_include()}/terraform.tfstate"
    region                      = "fr-par"
    endpoints = {
      s3 = "https://s3.fr-par.scw.cloud"
    }
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}
