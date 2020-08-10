/**
 * Copyright 2018 Google LLC
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

variable "region" {
  default = "us-central1"
}

variable "host_project" {
  description = "ID for the Shared VPC host project"
}

variable "service_project" {
  description = "ID for the Shared VPC service project where instances will be deployed"
}

variable "network" {
  description = "ID of network to launch instances on"
}

variable "subnetwork" {
  description = "ID of subnetwork to launch instances on"
}

variable "group_size" {
  default     = "2"
  description = "Size of managed instance group to create"
}
