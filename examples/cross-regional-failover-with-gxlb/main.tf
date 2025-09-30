resource "google_compute_network" "global_lb_network" {
  name                    = "global-lb-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vm_subnets" {
  for_each      = var.regions
  name          = "global-backend-${each.key}-vm-subnet"
  region        = each.key
  network       = google_compute_network.global_lb_network.self_link
  ip_cidr_range = var.vm_subnet_cidrs[each.key]
}

resource "google_compute_firewall" "allow_global_hc" {
  name    = "allow-global-lb-health-checks"
  network = google_compute_network.global_lb_network.name
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["allow-health-check"]
}

resource "google_compute_instance_template" "global_backend_tmpl" {
  for_each     = var.regions
  name_prefix  = "global-backend-${each.key}-tmpl-"
  machine_type = var.instance_machine_type
  tags         = ["allow-health-check"]

  disk {
    source_image = var.instance_image
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vm_subnets[each.key].self_link
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    echo "Hello from Global LB Backend in ${each.key}" > /var/www/html/index.html
    systemctl enable nginx
    systemctl restart nginx
  EOT
}

resource "google_compute_instance_group_manager" "global_backend_migs" {
  for_each           = var.regions
  name               = "global-backend-${each.key}-mig"
  base_instance_name = "global-backend-${each.key}-vm"
  zone               = var.region_to_zone[each.key]
  target_size        = var.target_size

  version {
    instance_template = google_compute_instance_template.global_backend_tmpl[each.key].self_link
  }
}

resource "google_compute_health_check" "global_lb_hc" {
  name                = "global-lb-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

resource "google_compute_security_policy" "global_armor" {
  name = "global-armor-policy"
  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default allow all rule"
  }
}

resource "google_compute_backend_service" "global_bs" {
  name                  = "global-lb-backend-service"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_health_check.global_lb_hc.self_link]
  security_policy       = google_compute_security_policy.global_armor.self_link
  enable_cdn            = true

  dynamic "backend" {
    for_each = var.regions
    content {
      group = google_compute_instance_group_manager.global_backend_migs[backend.key].instance_group
    }
  }
}

resource "google_compute_url_map" "global_um" {
  name            = "global-lb-url-map"
  default_service = google_compute_backend_service.global_bs.id
}

resource "google_compute_target_https_proxy" "global_https_proxy" {
  name            = "global-lb-https-proxy"
  url_map         = google_compute_url_map.global_um.id
  certificate_map = "//certificatemanager.googleapis.com/${google_certificate_manager_certificate_map.global_cert_map.id}"
}

resource "google_compute_global_address" "global_addr" {
  name = "global-lb-ip"
}

resource "google_compute_global_forwarding_rule" "global_fr" {
  name                  = "global-lb-forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.global_https_proxy.id
  ip_address            = google_compute_global_address.global_addr.address
}

locals {
  dns_managed_zone_name = var.create_public_zone && var.enable_dns_records ? google_dns_managed_zone.public_new[0].name : var.public_zone_name
}

resource "google_dns_managed_zone" "public_new" {
  count       = var.create_public_zone && var.enable_dns_records ? 1 : 0
  name        = format("public-%s", replace(var.hostname, ".", "-"))
  dns_name    = "${var.hostname}."
  description = "Public zone for ${var.hostname}"
}

resource "google_certificate_manager_dns_authorization" "global_auth" {
  provider = google-beta
  name     = "global-dns-auth"
  domain   = var.hostname
}

resource "google_certificate_manager_certificate" "global_cert" {
  provider = google-beta
  name     = "global-cm-cert"
  managed {
    domains            = [var.hostname]
    dns_authorizations = [google_certificate_manager_dns_authorization.global_auth.id]
  }
}

resource "google_certificate_manager_certificate_map" "global_cert_map" {
  provider = google-beta
  name     = "global-lb-cert-map"
}

resource "google_certificate_manager_certificate_map_entry" "global_cert_map_entry" {
  provider     = google-beta
  name         = "global-lb-cert-map-entry"
  map          = google_certificate_manager_certificate_map.global_cert_map.name
  certificates = [google_certificate_manager_certificate.global_cert.id]
  hostname     = var.hostname
}

resource "google_dns_record_set" "global_acme_txt" {
  count = var.enable_dns_records && length(local.dns_managed_zone_name) > 0 ? 1 : 0

  managed_zone = local.dns_managed_zone_name
  name         = google_certificate_manager_dns_authorization.global_auth.dns_resource_record[0].name
  type         = google_certificate_manager_dns_authorization.global_auth.dns_resource_record[0].type
  ttl          = 60
  rrdatas      = [google_certificate_manager_dns_authorization.global_auth.dns_resource_record[0].data]
}

resource "google_dns_record_set" "global_a" {
  count = var.enable_dns_records && length(local.dns_managed_zone_name) > 0 ? 1 : 0

  managed_zone = local.dns_managed_zone_name
  name         = "${var.hostname}."
  type         = "A"
  ttl          = 60
  rrdatas      = [google_compute_global_address.global_addr.address]
}
