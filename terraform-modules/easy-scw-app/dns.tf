resource "scaleway_domain_record" "scienta_domain" {
  for_each = var.scienta_domain != null ? { enabled = var.scienta_domain } : {}

  dns_zone = "scienta.cloud"
  name     = var.scienta_domain
  type     = "CNAME"
  data     = "${scaleway_container.main.domain_name}."
  ttl      = 600
}

resource "scaleway_container_domain" "app" {
  for_each = var.scienta_domain != null ? { enabled = var.scienta_domain } : {}

  container_id = scaleway_container.main.id
  hostname     = "${scaleway_domain_record.scienta_domain["enabled"].name}.${scaleway_domain_record.scienta_domain["enabled"].dns_zone}"
}
