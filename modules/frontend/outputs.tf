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

output "ip_address_internal_managed_http" {
  description = "The internal/external IP addresses assigned to the HTTP forwarding rules."
  value       = [for rule in google_compute_global_forwarding_rule.internal_managed_http : rule.ip_address]
}

output "ip_address_internal_managed_https" {
  description = "The internal/external IP addresses assigned to the HTTPS forwarding rules."
  value       = [for rule in google_compute_global_forwarding_rule.internal_managed_https : rule.ip_address]
}

output "external_ip" {
  description = "The external IPv4 assigned to the global fowarding rule."
  value       = local.address
}

output "external_ipv6_address" {
  description = "The external IPv6 assigned to the global fowarding rule."
  value       = local.ipv6_address
}

output "ipv6_enabled" {
  description = "Whether IPv6 configuration is enabled on this load-balancer"
  value       = var.enable_ipv6
}

output "http_proxy" {
  description = "The HTTP proxy used by this module."
  value       = google_compute_target_http_proxy.default[*].self_link
}

output "https_proxy" {
  description = "The HTTPS proxy used by this module."
  value       = google_compute_target_https_proxy.default[*].self_link
}

output "url_map" {
  description = "The default URL map used by this module."
  value       = google_compute_url_map.default[*].self_link
}

output "ssl_certificate_created" {
  description = "The SSL certificate create from key/pem"
  value       = google_compute_ssl_certificate.default[*].self_link
}

output "apphub_service_uri" {
  value = concat(
    local.create_http_forward && !local.is_internal_managed ? [
      {
        service_uri = "//compute.googleapis.com/${google_compute_global_forwarding_rule.http[0].id}"
        service_id  = substr("${google_compute_global_forwarding_rule.http[0].name}-${md5("global-lb-${var.project_id}")}", 0, 63)
        location    = "global"
      }
    ] : [],
    var.ssl && !local.is_internal_managed ? [
      {
        service_uri = "//compute.googleapis.com/${google_compute_global_forwarding_rule.https[0].id}"
        service_id  = substr("${google_compute_global_forwarding_rule.https[0].name}-${md5("global-lb-${var.project_id}")}", 0, 63)
        location    = "global"
      }
    ] : [],
    (var.enable_ipv6 && local.create_http_forward && !local.is_internal_managed) ? [
      {
        service_uri = "//compute.googleapis.com/${google_compute_global_forwarding_rule.http_ipv6[0].id}"
        service_id  = substr("${google_compute_global_forwarding_rule.http_ipv6[0].name}-${md5("global-lb-${var.project_id}")}", 0, 63)
        location    = "global"
      }
    ] : [],
    var.enable_ipv6 && var.ssl && !local.is_internal_managed ? [
      {
        service_uri = "//compute.googleapis.com/${google_compute_global_forwarding_rule.https_ipv6[0].id}"
        service_id  = substr("${google_compute_global_forwarding_rule.https_ipv6[0].name}-${md5("global-lb-${var.project_id}")}", 0, 63)
        location    = "global"
      }
    ] : [],
  )
  description = "Service URI in CAIS style to be used by Apphub."
}
