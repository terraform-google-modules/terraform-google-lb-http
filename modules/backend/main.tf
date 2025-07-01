/**
 * Copyright 2024 Google LLC
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
  is_backend_bucket       = var.backend_bucket_name != null && var.backend_bucket_name != ""
  serverless_neg_backends = local.is_backend_bucket ? [] : var.serverless_neg_backends
}

resource "google_compute_backend_service" "default" {
  provider = google-beta
  count    = !local.is_backend_bucket ? 1 : 0

  project = var.project_id
  name    = var.name

  load_balancing_scheme = var.load_balancing_scheme

  port_name = var.port_name
  protocol  = var.protocol

  description                     = var.description
  connection_draining_timeout_sec = var.connection_draining_timeout_sec
  enable_cdn                      = var.enable_cdn
  compression_mode                = var.load_balancing_scheme == "INTERNAL_SELF_MANAGED" || var.load_balancing_scheme == "INTERNAL_MANAGED" ? null : var.compression_mode
  custom_request_headers          = var.custom_request_headers
  custom_response_headers         = var.custom_response_headers
  session_affinity                = var.session_affinity
  affinity_cookie_ttl_sec         = var.affinity_cookie_ttl_sec
  locality_lb_policy              = var.locality_lb_policy
  edge_security_policy            = var.edge_security_policy
  security_policy                 = var.security_policy
  timeout_sec                     = var.timeout_sec

  health_checks = var.health_check != null ? google_compute_health_check.default[*].self_link : null

  dynamic "backend" {
    for_each = toset(var.groups)
    content {
      description = lookup(backend.value, "description", null)
      group       = backend.value["group"]

      balancing_mode               = backend.value["balancing_mode"]
      capacity_scaler              = backend.value["capacity_scaler"]
      max_connections              = backend.value["max_connections"]
      max_connections_per_instance = backend.value["max_connections_per_instance"]
      max_connections_per_endpoint = backend.value["max_connections_per_endpoint"]
      max_rate                     = backend.value["max_rate"]
      max_rate_per_instance        = backend.value["max_rate_per_instance"]
      max_rate_per_endpoint        = backend.value["max_rate_per_endpoint"]
      max_utilization              = backend.value["max_utilization"]
    }
  }

  dynamic "backend" {
    for_each = toset(var.serverless_neg_backends)
    content {
      group = google_compute_region_network_endpoint_group.serverless_negs["neg-${var.name}-${backend.value.service_name}-${backend.value.region}"].id
    }
  }

  dynamic "log_config" {
    for_each = var.log_config.enable ? [1] : []
    content {
      enable      = var.log_config.enable
      sample_rate = var.log_config.sample_rate
    }
  }

  dynamic "iap" {
    for_each = var.iap_config.enable ? [1] : []
    content {
      oauth2_client_id     = lookup(var.iap_config, "oauth2_client_id", "")
      enabled              = var.iap_config.enable
      oauth2_client_secret = lookup(var.iap_config, "oauth2_client_secret", "")
    }
  }

  dynamic "cdn_policy" {
    for_each = var.enable_cdn ? [1] : []
    content {
      cache_mode                   = var.cdn_policy.cache_mode
      signed_url_cache_max_age_sec = var.cdn_policy.signed_url_cache_max_age_sec
      default_ttl                  = var.cdn_policy.default_ttl
      max_ttl                      = var.cdn_policy.max_ttl
      client_ttl                   = var.cdn_policy.client_ttl
      negative_caching             = var.cdn_policy.negative_caching
      serve_while_stale            = var.cdn_policy.serve_while_stale

      dynamic "negative_caching_policy" {
        for_each = var.cdn_policy.negative_caching_policy != null ? [1] : []
        content {
          code = var.cdn_policy.negative_caching_policy.code
          ttl  = var.cdn_policy.negative_caching_policy.ttl
        }
      }

      dynamic "cache_key_policy" {
        for_each = var.cdn_policy.cache_key_policy != null ? [1] : []
        content {
          include_host           = var.cdn_policy.cache_key_policy.include_host
          include_protocol       = var.cdn_policy.cache_key_policy.include_protocol
          include_query_string   = var.cdn_policy.cache_key_policy.include_query_string
          query_string_blacklist = var.cdn_policy.cache_key_policy.query_string_blacklist
          query_string_whitelist = var.cdn_policy.cache_key_policy.query_string_whitelist
          include_http_headers   = var.cdn_policy.cache_key_policy.include_http_headers
          include_named_cookies  = var.cdn_policy.cache_key_policy.include_named_cookies
        }
      }

      dynamic "bypass_cache_on_request_headers" {
        for_each = toset(var.cdn_policy.bypass_cache_on_request_headers) != null ? var.cdn_policy.bypass_cache_on_request_headers : []
        content {
          header_name = bypass_cache_on_request_headers.value
        }
      }
    }
  }

  dynamic "outlier_detection" {
    for_each = var.outlier_detection != null && (var.load_balancing_scheme == "INTERNAL_SELF_MANAGED" || var.load_balancing_scheme == "EXTERNAL_MANAGED") ? [1] : []
    content {
      consecutive_errors                    = var.outlier_detection.consecutive_errors
      consecutive_gateway_failure           = var.outlier_detection.consecutive_gateway_failure
      enforcing_consecutive_errors          = var.outlier_detection.enforcing_consecutive_errors
      enforcing_consecutive_gateway_failure = var.outlier_detection.enforcing_consecutive_gateway_failure
      enforcing_success_rate                = var.outlier_detection.enforcing_success_rate
      max_ejection_percent                  = var.outlier_detection.max_ejection_percent
      success_rate_minimum_hosts            = var.outlier_detection.success_rate_minimum_hosts
      success_rate_request_volume           = var.outlier_detection.success_rate_request_volume
      success_rate_stdev_factor             = var.outlier_detection.success_rate_stdev_factor

      dynamic "base_ejection_time" {
        for_each = var.outlier_detection.base_ejection_time != null ? [1] : []
        content {
          seconds = var.outlier_detection.base_ejection_time.seconds
          nanos   = var.outlier_detection.base_ejection_time.nanos
        }
      }

      dynamic "interval" {
        for_each = var.outlier_detection.interval != null ? [1] : []
        content {
          seconds = var.outlier_detection.interval.seconds
          nanos   = var.outlier_detection.interval.nanos
        }
      }
    }
  }
}

resource "google_compute_region_network_endpoint_group" "serverless_negs" {
  for_each = { for serverless_neg_backend in local.serverless_neg_backends :
  "neg-${var.name}-${serverless_neg_backend.service_name}-${serverless_neg_backend.region}" => serverless_neg_backend }


  provider              = google-beta
  project               = var.project_id
  name                  = each.key
  network_endpoint_type = "SERVERLESS"
  region                = each.value.region

  dynamic "cloud_run" {
    for_each = each.value.type == "cloud-run" ? [1] : []
    content {
      service = each.value.service_name
    }
  }

  dynamic "cloud_function" {
    for_each = each.value.type == "cloud-function" ? [1] : []
    content {
      function = each.value.service_name
    }
  }

  dynamic "app_engine" {
    for_each = each.value.type == "app-engine" ? [1] : []
    content {
      service = each.value.service_name
      version = each.value.service_version
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_health_check" "default" {
  provider = google-beta
  count    = var.health_check != null ? 1 : 0
  project  = var.project_id
  name     = "${var.name}-hc"

  check_interval_sec  = var.health_check.check_interval_sec
  timeout_sec         = var.health_check.timeout_sec
  healthy_threshold   = var.health_check.healthy_threshold
  unhealthy_threshold = var.health_check.unhealthy_threshold

  log_config {
    enable = var.health_check.logging
  }

  dynamic "http_health_check" {
    for_each = coalesce(var.health_check.protocol, var.protocol) == "HTTP" ? [
      1
    ] : []

    content {
      host               = var.health_check.host
      request_path       = var.health_check.request_path
      response           = var.health_check.response
      port               = var.health_check.port
      port_name          = var.health_check.port_name
      proxy_header       = var.health_check.proxy_header
      port_specification = var.health_check.port_specification
    }
  }

  dynamic "https_health_check" {
    for_each = coalesce(var.health_check.protocol, var.protocol) == "HTTPS" ? [
      1
    ] : []

    content {
      host               = var.health_check.host
      request_path       = var.health_check.request_path
      response           = var.health_check.response
      port               = var.health_check.port
      port_name          = var.health_check.port_name
      proxy_header       = var.health_check.proxy_header
      port_specification = var.health_check.port_specification
    }
  }

  dynamic "http2_health_check" {
    for_each = coalesce(var.health_check.protocol, var.protocol) == "HTTP2" ? [
      1
    ] : []

    content {
      host               = var.health_check.host
      request_path       = var.health_check.request_path
      response           = var.health_check.response
      port               = var.health_check.port
      port_name          = var.health_check.port_name
      proxy_header       = var.health_check.proxy_header
      port_specification = var.health_check.port_specification
    }
  }

  dynamic "tcp_health_check" {
    for_each = coalesce(var.health_check.protocol, var.protocol) == "TCP" ? [
      1
    ] : []

    content {
      request            = var.health_check.request
      response           = var.health_check.response
      port               = var.health_check.port
      port_name          = var.health_check.port_name
      proxy_header       = var.health_check.proxy_header
      port_specification = var.health_check.port_specification
    }
  }
}

resource "google_compute_firewall" "default-hc" {
  count   = var.health_check != null ? length(var.firewall_networks) : 0
  project = length(var.firewall_networks) == 1 && var.firewall_projects[0] == "default" ? var.project_id : var.firewall_projects[count.index]
  name    = "${var.name}-hc-${count.index}"
  network = var.firewall_networks[count.index]
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
  target_tags             = length(var.target_tags) > 0 ? var.target_tags : null
  target_service_accounts = length(var.target_service_accounts) > 0 ? var.target_service_accounts : null

  allow {
    protocol = "tcp"
    ports    = var.health_check.port != null ? [var.health_check.port] : null
  }
}

resource "google_compute_firewall" "allow_proxy" {
  count         = var.health_check != null ? length(var.firewall_networks) : 0
  project       = length(var.firewall_networks) == 1 && var.firewall_projects[0] == "default" ? var.project_id : var.firewall_projects[count.index]
  name          = "${var.name}-fw-allow-proxies-${count.index}"
  network       = var.firewall_networks[count.index]
  source_ranges = var.firewall_source_ranges
  target_tags   = length(var.target_tags) > 0 ? var.target_tags : null
  allow {
    ports    = ["443"]
    protocol = "tcp"
  }
  allow {
    ports    = ["80"]
    protocol = "tcp"
  }
  allow {
    ports    = ["8080"]
    protocol = "tcp"
  }
}

resource "google_compute_backend_bucket" "default" {
  provider = google-beta
  count    = local.is_backend_bucket ? 1 : 0

  project     = var.project_id
  name        = var.name
  bucket_name = var.backend_bucket_name
  enable_cdn  = var.enable_cdn

  description = var.description

  # CDN policy configuration, if CDN is enabled
  dynamic "cdn_policy" {
    for_each = var.enable_cdn ? [1] : []
    content {
      cache_mode                   = var.cdn_policy.cache_mode
      signed_url_cache_max_age_sec = var.cdn_policy.signed_url_cache_max_age_sec
      default_ttl                  = var.cdn_policy.default_ttl
      max_ttl                      = var.cdn_policy.max_ttl
      client_ttl                   = var.cdn_policy.client_ttl
      negative_caching             = var.cdn_policy.negative_caching
      serve_while_stale            = var.cdn_policy.serve_while_stale

      dynamic "negative_caching_policy" {
        for_each = var.cdn_policy.negative_caching_policy != null ? [1] : []
        content {
          code = var.cdn_policy.negative_caching_policy.code
          ttl  = var.cdn_policy.negative_caching_policy.ttl
        }
      }

      dynamic "cache_key_policy" {
        for_each = var.cdn_policy.cache_key_policy != null ? [1] : []
        content {
          query_string_whitelist = var.cdn_policy.cache_key_policy.query_string_whitelist
          include_http_headers   = var.cdn_policy.cache_key_policy.include_http_headers
        }
      }

      dynamic "bypass_cache_on_request_headers" {
        for_each = var.cdn_policy.bypass_cache_on_request_headers != null && try(length(var.cdn_policy.bypass_cache_on_request_headers), 0) > 0 ? toset(var.cdn_policy.bypass_cache_on_request_headers) : []
        content {
          header_name = bypass_cache_on_request_headers.value
        }
      }
    }
  }
}
