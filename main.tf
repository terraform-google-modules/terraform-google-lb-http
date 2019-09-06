/*
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  bp_maps = [for bp in var.backend_params: {
    path      = split(",", bp)[0],
    port_name = split(",", bp)[1],
    port      = split(",", bp)[2],
    timeout   = split(",", bp)[3],
    substr_hashed_path = substr(md5(split(",", bp)[0]), 0, 8)
  }]
}

resource "google_compute_global_forwarding_rule" "http" {
  project    = var.project
  count      = var.http_forward ? 1 : 0
  name       = var.name
  target     = google_compute_target_http_proxy.default[0].self_link
  ip_address = google_compute_global_address.default.address
  port_range = "80"
  depends_on = [
    google_compute_global_address.default]
}

resource "google_compute_global_forwarding_rule" "https" {
  project    = var.project
  count      = var.ssl ? 1 : 0
  name       = "${var.name}-https"
  target     = google_compute_target_https_proxy.default[0].self_link
  ip_address = google_compute_global_address.default.address
  port_range = "443"
  depends_on = [
    google_compute_global_address.default]
}

resource "google_compute_global_address" "default" {
  project    = var.project
  name       = "${var.name}-address"
  ip_version = var.ip_version
}

# HTTP proxy when ssl is false
resource "google_compute_target_http_proxy" "default" {
  project = var.project
  count   = var.http_forward ? 1 : 0
  name    = "${var.name}-http-proxy"
  url_map = compact(
  concat([
    var.url_map], google_compute_url_map.default.*.self_link),
  )[0]
}

# HTTPS proxy  when ssl is true
resource "google_compute_target_https_proxy" "default" {
  project          = var.project
  count            = var.ssl ? 1 : 0
  name             = "${var.name}-https-proxy"
  url_map          = compact(
  concat([
    var.url_map], google_compute_url_map.default.*.self_link), )[0]
  ssl_certificates = compact(concat(var.ssl_certificates, google_compute_ssl_certificate.default.*.self_link, ), )
}

resource "google_compute_ssl_certificate" "default" {
  project     = var.project
  count       = var.ssl && false == var.use_ssl_certificates ? 1 : 0
  name_prefix = "${var.name}-certificate-"
  private_key = var.private_key
  certificate = var.certificate

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_url_map" "default" {
  project         = var.project
  count           = var.create_url_map ? 1 : 0
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_service.default[keys(var.backends)[0]].self_link
}

resource "google_compute_backend_service" "default" {
  for_each = toset(keys(var.backends))

  project     = var.project
  #  name        = "${var.name}-backend-${split(",", each.value)[1]}-${split(",", each.value)[2]}"
  name        = "${var.name}-backend-${each.value}"

  port_name   = local.bp_maps[tonumber(each.value)]["port_name"]
  protocol    = var.backend_protocol
  timeout_sec = local.bp_maps[tonumber(each.value)]["timeout"]

  dynamic "backend" {
    # keeping the old interface(var.backends) looks like overkill here
    for_each = var.backends[each.value]
    content {
      balancing_mode               = lookup(backend.value, "balancing_mode", null)
      capacity_scaler              = lookup(backend.value, "capacity_scaler", null)
      description                  = lookup(backend.value, "description", null)
      group                        = lookup(backend.value, "group", null)
      max_connections              = lookup(backend.value, "max_connections", null)
      max_connections_per_instance = lookup(backend.value, "max_connections_per_instance", null)
      max_rate                     = lookup(backend.value, "max_rate", null)
      max_rate_per_instance        = lookup(backend.value, "max_rate_per_instance", null)
      max_utilization              = lookup(backend.value, "max_utilization", null)
    }
  }

  health_checks = [
    google_compute_health_check.default[tonumber(each.value)].self_link]

  security_policy = var.security_policy
  enable_cdn      = var.cdn
}

resource "google_compute_health_check" "default" {
  # Note:
  #  - tf supports only sets of stings, so options below don't work
  #     for_each = local.bp_maps # - not supported type
  #     for_each = toset(range(length(local.bp_maps))) # - not supported type
  #     for_each = toset(keys(var.backends)) # requires calling type conversion function
  #  - keeping the old interface(var.backed_params) is a bit too expensive
  # without changing the itnerface count.index works better than for_each
  count = length(local.bp_maps)
  name = "${var.name}-${local.bp_maps[count.index]["port_name"]}-${local.bp_maps[count.index]["port"]}-${local.bp_maps[count.index]["substr_hashed_path"]}"
  timeout_sec = local.bp_maps[count.index]["timeout"]
  check_interval_sec = local.bp_maps[count.index]["timeout"] + local.bp_maps[count.index]["timeout"] / 2
  project     = var.project

  http_health_check {
    request_path = local.bp_maps[count.index]["path"]
    port         = local.bp_maps[count.index]["port"]
  }
}

# Create firewall rule for each backend in each network specified
resource "google_compute_firewall" "default" {
  for_each = toset(var.firewall_networks)

  name          = "${var.name}-${each.value}-hc"
  # as the cross-project reference broken in https://github.com/terraform-google-modules/terraform-google-vm/issues/29
  # and as there are some level of uncertenity that support for more than one is cross-referenced project ever worked
  # we're limiting cross-referenced project to only one replacing list with string
  project       = var.firewall_projects != null ? var.firewall_projects : var.project
  network       = each.value
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16",
    "209.85.152.0/22",
    "209.85.204.0/22"]
  target_tags   = var.target_tags

  dynamic "allow" {
    for_each = distinct(var.backend_params)
    content {
      protocol = "tcp"
      ports    = [
        split(",", allow.value)[2]]
    }
  }
}
