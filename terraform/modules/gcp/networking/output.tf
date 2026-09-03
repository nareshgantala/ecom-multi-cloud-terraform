output "app_subnet_name" {
  value = google_compute_subnetwork.app_subnet.name
}
output "frontend_subnet_name" {
  value = google_compute_subnetwork.frontend_subnet.name
}

output "database_subnet_name" {
  value = google_compute_subnetwork.database_subnet.name
}

output "vpc_network_id" {
  value = google_compute_network.vpc_network.id
}
