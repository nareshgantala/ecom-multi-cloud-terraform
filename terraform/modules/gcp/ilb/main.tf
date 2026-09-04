resource "google_compute_subnetwork" "proxy_subnet" {
  name          = "${var.name_prefix}-proxy-subnet"
  ip_cidr_range = "10.128.0.0/24" # Any unused range in your VPC
  region        = "us-west1"
  network       = var.network_id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}


# 1. Reserve Static Private IP for the Load Balancer VIP
resource "google_compute_address" "ilb_ip" {
  name         = "${var.name_prefix}-app-ilb-ip"
  subnetwork   = var.app_subnet_id
  address_type = "INTERNAL"
}

# 2. Regional Health Checks (one per service port)
resource "google_compute_region_health_check" "app_hc" {
  for_each = var.app_services
  name     = "${var.name_prefix}-${each.key}-hc"

  check_interval_sec = 5
  timeout_sec        = 5

  tcp_health_check {
    port = each.value.port
  }
}

# 3. Regional Backend Services (INTERNAL_MANAGED)
resource "google_compute_region_backend_service" "app_backend" {
  for_each = var.app_services
  name     = "${var.name_prefix}-${each.key}-backend"

  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "INTERNAL_MANAGED"
  timeout_sec           = 10

  backend {
    group           = each.value.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }

  health_checks = [google_compute_region_health_check.app_hc[each.key].id]
}

# 4. Regional URL Map with Host-Based Routing
resource "google_compute_region_url_map" "ilb_url_map" {
  name            = "${var.name_prefix}-app-ilb-url-map"
  default_service = google_compute_region_backend_service.app_backend["catalogue"].id

  # Dynamic Host Rules: orders.naresh-training.online -> orders backend, etc.
  dynamic "host_rule" {
    for_each = var.app_services
    content {
      hosts        = ["${host_rule.key}.${var.domain_name}"]
      path_matcher = host_rule.key
    }
  }

  dynamic "path_matcher" {
    for_each = var.app_services
    content {
      name            = path_matcher.key
      default_service = google_compute_region_backend_service.app_backend[path_matcher.key].id
    }
  }
}

# 5. Regional Target HTTP Proxy
resource "google_compute_region_target_http_proxy" "ilb_proxy" {
  name    = "${var.name_prefix}-app-ilb-proxy"
  url_map = google_compute_region_url_map.ilb_url_map.id
}

# 6. Regional Internal Forwarding Rule
resource "google_compute_forwarding_rule" "ilb_forwarding_rule" {
  name                  = "${var.name_prefix}-app-ilb-forwarding-rule"
  load_balancing_scheme = "INTERNAL_MANAGED"
  network               = var.network_id
  subnetwork            = var.app_subnet_id
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.ilb_proxy.id
  ip_address            = google_compute_address.ilb_ip.address
  depends_on            = [google_compute_subnetwork.proxy_subnet]
}
