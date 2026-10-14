/**
 * Copyright 2026 Google LLC
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

output "load_balancer_ip" {
  value       = module.gce_lb_https.external_ip
  description = "The external IPv4 address of the load balancer"
}

output "load_balancer_ipv6" {
  value       = module.gce_lb_https.ipv6_enabled ? module.gce_lb_https.external_ipv6_address : null
  description = "The IPv6 address of the load-balancer, if enabled; else null"
}

output "ssl_policy_name" {
  value       = google_compute_ssl_policy.main.name
  description = "The name of the SSL policy with PQC enabled"
}

output "project_id" {
  value       = var.project
  description = "The project ID"
}
