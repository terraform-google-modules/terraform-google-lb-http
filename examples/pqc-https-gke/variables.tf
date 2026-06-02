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

variable "name" {
  description = "The name for the load balancer and associated resources"
  type        = string
  default     = "tf-lb-https-gke"
}

variable "service_port" {
  description = "The port on the node to connect to"
  type        = string
  default     = "30000"
}

variable "service_port_name" {
  description = "The name of the port on the node to connect to"
  type        = string
  default     = "http"
}

variable "target_tags" {
  description = "The target tags for the firewall rules"
  type        = string
  default     = "tf-lb-https-gke"
}

variable "backend" {
  description = "The instance group to add to the backend"
  type        = string
}

variable "network_name" {
  description = "The name of the network to create the load balancer in"
  type        = string
  default     = "default"
}

variable "project" {
  description = "The project ID"
  type        = string
}
