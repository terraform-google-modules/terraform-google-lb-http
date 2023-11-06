/**
 * Copyright 2023 Google LLC
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

output "group1_region" {
  value = var.group1_region
}

output "project_id" {
  value = var.project_id
}

output "load-balancer-ip" {
  value = module.gce-lb-https.external_ip
}

output "asset-url" {
  value = "https://${module.gce-lb-https.external_ip}/assets/gcp-logo.svg"
}
