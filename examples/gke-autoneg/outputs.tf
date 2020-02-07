/**
 * Copyright 2020 Google LLC
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

output "backend-name" {
  value       = module.lb-http.backend_services["default"].name
  description = "Backend service name to use in autoneg annotations"
}

output "lb" {
  value       = module.lb-http
  description = "Full load balancer configuration"
}

output "endpoint" {
  value       = module.lb-http.external_ip
  description = "External IP to access load balancer"
}

output "project" {
  value       = var.project
  description = "Project ID configured for resources"
}
