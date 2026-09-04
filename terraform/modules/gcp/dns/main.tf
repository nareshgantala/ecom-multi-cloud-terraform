resource "google_dns_record_set" "app_records" {
  for_each     = var.app_services
  name         = "${each.key}.${data.google_dns_managed_zone.public_zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.public_zone.name
  rrdatas      = [var.ilb_ip]
}

resource "google_dns_record_set" "elb_dns_record" {
  name         = data.google_dns_managed_zone.public_zone.dns_name
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.public_zone.name
  rrdatas      = [var.elb_ip]
}
