resource "google_compute_global_forwarding_rule" "http" {
  name       = "${var.name}"
  target     = "${google_compute_target_http_proxy.default.self_link}"
  ip_address = "${google_compute_global_address.default.address}"
  port_range = "80"
  depends_on = ["google_compute_global_address.default"]
}

resource "google_compute_global_forwarding_rule" "https" {
  count      = "${var.ssl ? 1 : 0}"
  name       = "${var.name}-https"
  target     = "${google_compute_target_https_proxy.default.self_link}"
  ip_address = "${google_compute_global_address.default.address}"
  port_range = "443"
  depends_on = ["google_compute_global_address.default"]
}

resource "google_compute_global_address" "default" {
  name = "${var.name}-address"
}

# HTTP proxy when ssl is false
resource "google_compute_target_http_proxy" "default" {
  name    = "${var.name}-http-proxy"
  url_map = "${element(compact(concat(list(var.url_map), google_compute_url_map.default.*.self_link)), 0)}"
}

# HTTPS proxy  when ssl is true
resource "google_compute_target_https_proxy" "default" {
  count            = "${var.ssl ? 1 : 0}"
  name             = "${var.name}-https-proxy"
  url_map          = "${element(compact(concat(list(var.url_map), google_compute_url_map.default.*.self_link)), 0)}"
  ssl_certificates = ["${google_compute_ssl_certificate.default.self_link}"]
}

resource "google_compute_ssl_certificate" "default" {
  count       = "${var.ssl ? 1 : 0}"
  name        = "${var.name}-certificate"
  private_key = "${var.private_key}"
  certificate = "${var.certificate}"
}

resource "google_compute_url_map" "default" {
  project         = "${var.project}"
  count           = "${var.create_url_map ? 1 : 0}"
  name            = "${var.name}-url-map"
  default_service = "${google_compute_backend_service.default.0.self_link}"
}

resource "google_compute_backend_service" "default" {
  project       = "${var.project}"
  count         = "${length(var.backend_params)}"
  name          = "${var.name}-backend-${count.index}"
  port_name     = "${element(split(",", element(var.backend_params, count.index)), 1)}"
  protocol      = "HTTP"
  timeout_sec   = "${element(split(",", element(var.backend_params, count.index)), 3)}"
  backend       = ["${var.backends["${count.index}"]}"]
  health_checks = ["${element(google_compute_http_health_check.default.*.self_link, count.index)}"]
}

resource "google_compute_http_health_check" "default" {
  project      = "${var.project}"
  count        = "${length(var.backend_params)}"
  name         = "${var.name}-backend-${count.index}"
  request_path = "${element(split(",", element(var.backend_params, count.index)), 0)}"
  port         = "${element(split(",", element(var.backend_params, count.index)), 2)}"
}

resource "google_compute_firewall" "default-hc" {
  project       = "${var.project}"
  count         = "${length(var.backend_params)}"
  name          = "${var.name}-hc-${count.index}"
  network       = "${var.network}"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["${var.target_tags}"]

  allow {
    protocol = "tcp"
    ports    = ["${element(split(",", element(var.backend_params, count.index)), 2)}"]
  }
}
