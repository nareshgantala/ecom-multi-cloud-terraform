resource "google_compute_subnetwork" "proxy_subnet" {
  name          = "${var.name_prefix}-proxy-subnet"
  ip_cidr_range = "10.128.0.0/24" # Any unused range in your VPC
  region        = "us-west1"
  network       = var.network_id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}
