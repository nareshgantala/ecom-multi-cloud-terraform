output "database_ips" {
  value = { for k, v in google_compute_address.db_ip : k => v.address }
}
