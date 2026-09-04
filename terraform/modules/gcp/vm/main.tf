data "google_compute_image" "rhel" {
  family  = "rhel-10"
  project = "rhel-cloud"
}

resource "google_compute_instance_template" "frontend_template" {
  count          = var.component_type == "frontend" ? 1 : 0
  name_prefix    = "${var.name_prefix}-${var.component}-template"
  description    = "This template is used to create frontend server instances."
  machine_type   = var.machine_type
  can_ip_forward = false
  tags           = ["frontend"]

  lifecycle {
    create_before_destroy = true
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  metadata_startup_script = fileexists("${path.root}/../../scripts/shell/${var.component}.sh") ? file("${path.root}/../../scripts/shell/${var.component}.sh") : <<-EOF
    #!/bin/bash
    useradd -m -s /bin/bash devops
    echo 'devops:DevOps12345' | chpasswd
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
  EOF

  // Create a new boot disk from an image
  disk {
    source_image = data.google_compute_image.rhel.self_link
    auto_delete  = true
    boot         = true
    disk_type    = "hyperdisk-balanced"
  }

  network_interface {
    subnetwork = var.subnet_name
  }

}

resource "google_compute_instance_template" "app_template" {
  count          = var.component_type == "app" ? 1 : 0
  name_prefix    = "${var.name_prefix}-${var.component}-template"
  description    = "This template is used to create app server instances."
  machine_type   = var.machine_type
  can_ip_forward = false
  tags           = ["app"]
  lifecycle {
    create_before_destroy = true
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  metadata_startup_script = fileexists("${path.root}/../../scripts/shell/${var.component}.sh") ? file("${path.root}/../../scripts/shell/${var.component}.sh") : <<-EOF
    #!/bin/bash
    useradd -m -s /bin/bash devops
    echo 'devops:DevOps12345' | chpasswd
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
  EOF

  // Create a new boot disk from an image
  disk {
    source_image = data.google_compute_image.rhel.self_link
    auto_delete  = true
    boot         = true
    disk_type    = "hyperdisk-balanced"
  }

  network_interface {
    subnetwork = var.subnet_name
  }

}

resource "google_compute_instance_template" "database_template" {
  count          = var.component_type == "database" ? 1 : 0
  name_prefix    = "${var.name_prefix}-${var.component}-template"
  description    = "This template is used to create app server instances."
  machine_type   = var.machine_type
  can_ip_forward = false
  tags           = ["database"]
  lifecycle {
    create_before_destroy = true
  }

  metadata_startup_script = fileexists("${path.root}/../../scripts/shell/${var.component}.sh") ? file("${path.root}/../../scripts/shell/${var.component}.sh") : <<-EOF
    #!/bin/bash
    useradd -m -s /bin/bash devops
    echo 'devops:DevOps12345' | chpasswd
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
  EOF

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image = data.google_compute_image.rhel.self_link
    auto_delete  = true
    boot         = true
    disk_type    = "hyperdisk-balanced"
  }

  network_interface {
    subnetwork = var.subnet_name
    network_ip = var.static_ip
  }

}
resource "google_compute_region_instance_group_manager" "frontend_igm-sr" {
  count = var.component_type == "frontend" ? 1 : 0

  name = "${var.name_prefix}-${var.component}-igm"

  base_instance_name = "${var.name_prefix}-${var.component}-igm-instance"
  region             = "us-west1"

  target_size = 1

  version {
    instance_template = google_compute_instance_template.frontend_template[count.index].self_link
    name              = "primary"
  }

  named_port {
    name = "http"
    port = 80
  }
  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 3
    max_unavailable_fixed = 0
  }



}

resource "google_compute_region_instance_group_manager" "app_igm-sr" {
  count = var.component_type == "app" ? 1 : 0

  name = "${var.name_prefix}-${var.component}-igm"

  base_instance_name = "${var.name_prefix}-${var.component}-igm-instance"
  region             = "us-west1"

  target_size = 1

  version {
    instance_template = google_compute_instance_template.app_template[count.index].self_link
    name              = "primary"
  }

  named_port {
    name = "http"
    port = var.port
  }
  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 3
    max_unavailable_fixed = 0
  }


}

resource "google_compute_region_instance_group_manager" "database_igm-sr" {
  count = var.component_type == "database" ? 1 : 0

  name = "${var.name_prefix}-${var.component}-igm"

  base_instance_name = "${var.name_prefix}-${var.component}-igm-instance"
  region             = "us-west1"

  target_size = 1

  version {
    instance_template = google_compute_instance_template.database_template[count.index].self_link
    name              = "primary"
  }
  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 3
    max_unavailable_fixed = 0
  }

}
