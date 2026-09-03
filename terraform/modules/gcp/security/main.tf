resource "google_compute_firewall" "allow_lb_to_frontend" {
  name          = "${var.name_prefix}-allow-lb-to-frontend"
  network       = var.network_id
  description   = "Allows traffic from LB to frontend"
  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["frontend"]
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}


resource "google_compute_firewall" "allow_frontend_to_app" {
  name        = "${var.name_prefix}-allow-frontend-to-app"
  network     = var.network_id
  description = "Allows traffic from frontend to app"
  direction   = "INGRESS"
  source_tags = ["frontend", "app"]
  target_tags = ["app"]
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
}

resource "google_compute_firewall" "allow_app_to_database" {
  name        = "${var.name_prefix}-allow-app-to-database"
  network     = var.network_id
  description = "Allows traffic from app to database"
  direction   = "INGRESS"
  source_tags = ["app"]
  target_tags = ["database"]
  allow {
    protocol = "tcp"
    ports    = ["3306", "27017", "5672", "6379"]
  }
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name          = "${var.name_prefix}-allow-iap-ssh"
  network       = var.network_id
  description   = "Allows traffic from IAP to all VMs"
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["app", "frontend", "database"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
