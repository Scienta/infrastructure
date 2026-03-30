resource "scaleway_iam_application" "main" {
  name = var.name
}

resource "scaleway_iam_api_key" "main" {
  application_id = scaleway_iam_application.main.id
}
