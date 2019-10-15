/**
 * Copyright 2017 Google LLC
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

output "cluster_name" {
  value = google_container_cluster.default.name
}

output "network_name" {
  value = var.network_name
}

output "port_name" {
  value = "http"
}

output "port_number" {
  value = var.node_port
}

output "instance_group" {
  value = google_container_cluster.default.instance_group_urls[0]
}

output "node_tag" {
  value = var.node_tag
}
