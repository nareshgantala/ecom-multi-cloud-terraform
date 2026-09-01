resource "google_compute_network" "vpc_network" {
  project                 = "project-b30e4ed9-1852-43c5-bfc"
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
}


resource "google_compute_subnetwork" "database_subnet" {
  name          = "${var.name_prefix}-database-subnet"
  ip_cidr_range = var.database_cidr
  network       = google_compute_network.vpc_network.id

}

resource "google_compute_router" "router" {
  name    = "${var.name_prefix}-router"
  network = google_compute_network.vpc_network.id
}


resource "google_compute_router_nat" "nat" {
  name                               = "${var.name_prefix}-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

