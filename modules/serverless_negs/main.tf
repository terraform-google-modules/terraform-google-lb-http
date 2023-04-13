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
  address      = var.create_address ? join("", google_compute_global_address.default.*.address) : var.address
  ipv6_address = var.create_ipv6_address ? join("", google_compute_global_address.default_ipv6.*.address) : var.ipv6_address

  url_map             = var.create_url_map ? join("", google_compute_url_map.default.*.self_link) : var.url_map
  create_http_forward = var.http_forward || var.https_redirect


  is_internal      = var.load_balancing_scheme == "INTERNAL_SELF_MANAGED"
  internal_network = local.is_internal ? var.network : null
}

### IPv4 block ###
resource "google_compute_global_forwarding_rule" "http" {
  provider              = google-beta
  project               = var.project
  count                 = local.create_http_forward ? 1 : 0
  name                  = var.name
  target                = google_compute_target_http_proxy.default[0].self_link
  ip_address            = local.address
  port_range            = "80"
  labels                = var.labels
  load_balancing_scheme = var.load_balancing_scheme
  network               = local.internal_network
}

resource "google_compute_global_forwarding_rule" "https" {
  provider              = google-beta
  project               = var.project
  count                 = var.ssl || var.certificate_map != null ? 1 : 0
  name                  = "${var.name}-https"
  target                = google_compute_target_https_proxy.default[0].self_link
  ip_address            = local.address
  port_range            = "443"
  labels                = var.labels
  load_balancing_scheme = var.load_balancing_scheme
  network               = local.internal_network
}

resource "google_compute_global_address" "default" {
  provider   = google-beta
  count      = local.is_internal ? 0 : var.create_address ? 1 : 0
  project    = var.project
  name       = "${var.name}-address"
  ip_version = "IPV4"
  labels     = var.labels
}
### IPv4 block ###

### IPv6 block ###
resource "google_compute_global_forwarding_rule" "http_ipv6" {
  provider              = google-beta
  project               = var.project
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
  project               = var.project
  count                 = var.enable_ipv6 && (var.ssl || var.certificate_map != null) ? 1 : 0
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
  project    = var.project
  name       = "${var.name}-ipv6-address"
  ip_version = "IPV6"
  labels     = var.labels
}
### IPv6 block ###

# HTTP proxy when http forwarding is true
resource "google_compute_target_http_proxy" "default" {
  project = var.project
  count   = local.create_http_forward ? 1 : 0
  name    = "${var.name}-http-proxy"
  url_map = var.https_redirect == false ? local.url_map : join("", google_compute_url_map.https_redirect.*.self_link)
}

# HTTPS proxy when ssl is true
resource "google_compute_target_https_proxy" "default" {
  project = var.project
  count   = var.ssl || var.certificate_map != null ? 1 : 0
  name    = "${var.name}-https-proxy"
  url_map = local.url_map

  ssl_certificates = compact(concat(var.ssl_certificates, google_compute_ssl_certificate.default.*.self_link, google_compute_managed_ssl_certificate.default.*.self_link, ), )
  certificate_map  = var.certificate_map != null ? "//certificatemanager.googleapis.com/${var.certificate_map}" : null
  ssl_policy       = var.ssl_policy
  quic_override    = var.quic == null ? "NONE" : var.quic ? "ENABLE" : "DISABLE"
}

resource "google_compute_ssl_certificate" "default" {
  project     = var.project
  count       = var.ssl && length(var.managed_ssl_certificate_domains) == 0 && !var.use_ssl_certificates ? 1 : 0
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
  project  = var.project
  count    = var.ssl && length(var.managed_ssl_certificate_domains) > 0 && !var.use_ssl_certificates ? 1 : 0
  name     = var.random_certificate_suffix == true ? random_id.certificate[0].hex : "${var.name}-cert"

  lifecycle {
    create_before_destroy = true
  }

  managed {
    domains = var.managed_ssl_certificate_domains
  }
}

resource "google_compute_url_map" "default" {
  project         = var.project
  count           = var.create_url_map ? 1 : 0
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_service.default[keys(var.backends)[0]].self_link
}

resource "google_compute_url_map" "https_redirect" {
  project = var.project
  count   = var.https_redirect ? 1 : 0
  name    = "${var.name}-https-redirect"
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_backend_service" "default" {
  provider = google-beta
  for_each = var.backends

  project = var.project
  name    = "${var.name}-backend-${each.key}"

  load_balancing_scheme = var.load_balancing_scheme

  port_name = lookup(each.value, "port_name", "http")
  protocol  = lookup(each.value, "protocol", "HTTP")

  description                     = lookup(each.value, "description", null)
  connection_draining_timeout_sec = lookup(each.value, "connection_draining_timeout_sec", null)
  enable_cdn                      = lookup(each.value, "enable_cdn", false)
  compression_mode                = lookup(each.value, "compression_mode", "DISABLED")
  custom_request_headers          = lookup(each.value, "custom_request_headers", [])
  custom_response_headers         = lookup(each.value, "custom_response_headers", [])
  session_affinity                = lookup(each.value, "session_affinity", null)
  affinity_cookie_ttl_sec         = lookup(each.value, "affinity_cookie_ttl_sec", null)


  # To achieve a null backend edge_security_policy, set each.value.edge_security_policy to "" (empty string), otherwise, it fallsback to var.edge_security_policy.
  edge_security_policy = lookup(each.value, "edge_security_policy") == "" ? null : (lookup(each.value, "edge_security_policy") == null ? var.edge_security_policy : each.value.edge_security_policy)

  # To achieve a null backend security_policy, set each.value.security_policy to "" (empty string), otherwise, it fallsback to var.security_policy.
  security_policy = lookup(each.value, "security_policy") == "" ? null : (lookup(each.value, "security_policy") == null ? var.security_policy : each.value.security_policy)

  dynamic "backend" {
    for_each = toset(each.value["groups"])
    content {
      description = lookup(backend.value, "description", null)
      group       = lookup(backend.value, "group")

    }
  }

  dynamic "log_config" {
    for_each = lookup(lookup(each.value, "log_config", {}), "enable", true) ? [1] : []
    content {
      enable      = lookup(lookup(each.value, "log_config", {}), "enable", true)
      sample_rate = lookup(lookup(each.value, "log_config", {}), "sample_rate", "1.0")
    }
  }

  dynamic "iap" {
    for_each = lookup(lookup(each.value, "iap_config", {}), "enable", false) ? [1] : []
    content {
      oauth2_client_id     = lookup(lookup(each.value, "iap_config", {}), "oauth2_client_id", "")
      oauth2_client_secret = lookup(lookup(each.value, "iap_config", {}), "oauth2_client_secret", "")
    }
  }

  dynamic "cdn_policy" {
    for_each = each.value.enable_cdn ? [1] : []
    content {
      cache_mode                   = each.value.cdn_policy.cache_mode
      signed_url_cache_max_age_sec = each.value.cdn_policy.signed_url_cache_max_age_sec
      default_ttl                  = each.value.cdn_policy.default_ttl
      max_ttl                      = each.value.cdn_policy.max_ttl
      client_ttl                   = each.value.cdn_policy.client_ttl
      negative_caching             = each.value.cdn_policy.negative_caching
      serve_while_stale            = each.value.cdn_policy.serve_while_stale

      dynamic "negative_caching_policy" {
        for_each = each.value.cdn_policy.negative_caching_policy != null ? [1] : []
        content {
          code = each.value.cdn_policy.negative_caching_policy.code
          ttl  = each.value.cdn_policy.negative_caching_policy.ttl
        }
      }

      dynamic "cache_key_policy" {
        for_each = each.value.cdn_policy.cache_key_policy != null ? [1] : []
        content {
          include_host           = each.value.cdn_policy.cache_key_policy.include_host
          include_protocol       = each.value.cdn_policy.cache_key_policy.include_protocol
          include_query_string   = each.value.cdn_policy.cache_key_policy.include_query_string
          query_string_blacklist = each.value.cdn_policy.cache_key_policy.query_string_blacklist
          query_string_whitelist = each.value.cdn_policy.cache_key_policy.query_string_whitelist
          include_http_headers   = each.value.cdn_policy.cache_key_policy.include_http_headers
          include_named_cookies  = each.value.cdn_policy.cache_key_policy.include_named_cookies
        }
      }
    }
  }


}

