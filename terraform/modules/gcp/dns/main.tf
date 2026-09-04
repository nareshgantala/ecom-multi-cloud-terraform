locals {
  database_ips = {
    mysql    = "10.3.0.10"
    valky    = "10.3.0.11"
    rabbitmq = "10.3.0.12"
    mongodb  = "10.3.0.13"
  }
}

# 1. Reserve static internal IPs in the database subnet
resource "google_compute_address" "db_ip" {
  for_each     = local.database_ips
  name         = "${var.name_prefix}-${each.key}-ip"
  subnetwork   = var.database_subnet_name
  address_type = "INTERNAL"
  address      = each.value
}


resource "google_dns_record_set" "db_records" {
  for_each     = google_compute_address.db_ip
  name         = "${each.key}.${data.google_dns_managed_zone.public_zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.public_zone.name
  rrdatas      = [each.value.address]
}


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
