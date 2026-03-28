resource "scaleway_domain_record" "foo" {
  dns_zone = "httpgw.scienta.cloud"
  name     = "foo"
  type     = "A"
  data     = "1.2.3.4"
  ttl      = 3600
}
