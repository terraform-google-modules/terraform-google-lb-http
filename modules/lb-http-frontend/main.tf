/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


locals {
  address      = var.create_address ? join("", google_compute_global_address.default[*].address) : var.address
  ipv6_address = var.create_ipv6_address ? join("", google_compute_global_address.default_ipv6[*].address) : var.ipv6_address

  url_map             = var.create_url_map ? join("", google_compute_url_map.default[*].self_link) : var.url_map_resource_uri
  create_http_forward = var.http_forward || var.https_redirect


  is_internal      = var.load_balancing_scheme == "INTERNAL_SELF_MANAGED"
  internal_network = local.is_internal ? var.network : null

  # Create a map with hosts as keys and empty lists as initial values
  hosts = toset([for service in var.url_map_input : service.host])
  backend_services_by_host = {
    for host in local.hosts :
    host => [
      for s in var.url_map_input :
      s if s.host == host
    ]
  }
}

### IPv4 block ###
resource "google_compute_global_forwarding_rule" "http" {
  provider              = google-beta
  project               = var.project_id
  count                 = local.create_http_forward ? 1 : 0
  name                  = var.name
  target                = google_compute_target_http_proxy.default[0].self_link
  ip_address            = local.address
  port_range            = var.http_port
  labels                = var.labels
  load_balancing_scheme = var.load_balancing_scheme
  network               = local.internal_network
}

resource "google_compute_global_forwarding_rule" "https" {
  provider              = google-beta
  project               = var.project_id
  count                 = var.ssl ? 1 : 0
  name                  = "${var.name}-https"
  target                = google_compute_target_https_proxy.default[0].self_link
  ip_address            = local.address
  port_range            = var.https_port
  labels                = var.labels
  load_balancing_scheme = var.load_balancing_scheme
  network               = local.internal_network
}

resource "google_compute_global_address" "default" {
  provider   = google-beta
  count      = local.is_internal ? 0 : var.create_address ? 1 : 0
  project    = var.project_id
  name       = "${var.name}-address"
  ip_version = "IPV4"
  labels     = var.labels
}
### IPv4 block ###

### IPv6 block ###
resource "google_compute_global_forwarding_rule" "http_ipv6" {
  provider              = google-beta
  project               = var.project_id
  count                 = (var.enable_ipv6 && local.create_http_forward) ? 1 : 0
  name                  = "${var.name}-ipv6-http"
  target                = google_compute_target_http_proxy.default[0].self_link
  ip_address            = local.ipv6_address
  port_range            = "80"
  labels                = var.labels
  load_balancing_scheme = var.load_balancing_scheme
  network               = local.internal_network
}

resource "google_compute_global_forwarding_rule" "https_ipv6" {
  provider              = google-beta
  project               = var.project_id
  count                 = var.enable_ipv6 && var.ssl ? 1 : 0
  name                  = "${var.name}-ipv6-https"
  target                = google_compute_target_https_proxy.default[0].self_link
  ip_address            = local.ipv6_address
  port_range            = "443"
  labels                = var.labels
  load_balancing_scheme = var.load_balancing_scheme
  network               = local.internal_network
}

resource "google_compute_global_address" "default_ipv6" {
  provider   = google-beta
  count      = local.is_internal ? 0 : (var.enable_ipv6 && var.create_ipv6_address) ? 1 : 0
  project    = var.project_id
  name       = "${var.name}-ipv6-address"
  ip_version = "IPV6"
  labels     = var.labels
}
### IPv6 block ###

# HTTP proxy when http forwarding is true
resource "google_compute_target_http_proxy" "default" {
  project = var.project_id
  count   = local.create_http_forward ? 1 : 0
  name    = "${var.name}-http-proxy"
  url_map = var.https_redirect == false ? local.url_map : join("", google_compute_url_map.https_redirect[*].self_link)
}

# HTTPS proxy when ssl is true
resource "google_compute_target_https_proxy" "default" {
  project = var.project_id
  count   = var.ssl ? 1 : 0
  name    = "${var.name}-https-proxy"
  url_map = local.url_map

  ssl_certificates            = compact(concat(var.ssl_certificates, google_compute_ssl_certificate.default[*].self_link, google_compute_managed_ssl_certificate.default[*].self_link, ), )
  certificate_map             = var.certificate_map != null ? "//certificatemanager.googleapis.com/${var.certificate_map}" : null
  ssl_policy                  = var.ssl_policy
  quic_override               = var.quic == null ? "NONE" : var.quic ? "ENABLE" : "DISABLE"
  server_tls_policy           = var.server_tls_policy
  http_keep_alive_timeout_sec = var.http_keep_alive_timeout_sec
}

resource "google_compute_ssl_certificate" "default" {
  project     = var.project_id
  count       = var.ssl && var.create_ssl_certificate ? 1 : 0
  name_prefix = "${var.name}-certificate-"
  private_key = var.private_key
  certificate = var.certificate

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_id" "certificate" {
  count       = var.random_certificate_suffix == true ? 1 : 0
  byte_length = 4
  prefix      = "${var.name}-cert-"

  keepers = {
    domains = join(",", var.managed_ssl_certificate_domains)
  }
}

resource "google_compute_managed_ssl_certificate" "default" {
  provider = google-beta
  project  = var.project_id
  count    = var.ssl && length(var.managed_ssl_certificate_domains) > 0 ? 1 : 0
  name     = var.random_certificate_suffix == true ? random_id.certificate[0].hex : "${var.name}-cert"

  lifecycle {
    create_before_destroy = true
  }

  managed {
    domains = var.managed_ssl_certificate_domains
  }
}

resource "google_compute_url_map" "https_redirect" {
  project = var.project_id
  count   = var.https_redirect ? 1 : 0
  name    = "${var.name}-https-redirect"
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_url_map" "default" {
  count           = var.create_url_map ? 1 : 0
  provider        = google-beta
  project         = var.project_id
  name            = "${var.name}-url-map"
  default_service = local.backend_services_by_host["*"][0].backend_service


  dynamic "host_rule" {
    for_each = local.backend_services_by_host
    content {
      hosts        = [host_rule.key]
      path_matcher = host_rule.key == "*" ? "default" : replace(host_rule.key, ".", "")
    }
  }

  dynamic "path_matcher" {
    for_each = local.backend_services_by_host
    content {
      name            = path_matcher.key == "*" ? "default" : replace(path_matcher.key, ".", "")
      default_service = path_matcher.value[0].backend_service

      dynamic "path_rule" {
        for_each = path_matcher.value
        content {
          paths   = [path_rule.value.path]
          service = path_rule.value.backend_service
        }
      }
    }
  }
}
