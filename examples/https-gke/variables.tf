/**
 * Copyright 2019 Google LLC
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
  default = "tf-lb-https-gke"
}

variable "service_port" {
  default = "30000"
}

variable "service_port_name" {
  default = "http"
}

variable "target_tags" {
  default = "tf-lb-https-gke"
}

variable "backend" {
  description = "Map backend indices to list of backend maps."
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-f"
}

variable "network_name" {
  default = "default"
}

variable "service_account" {
  type = object({
    email  = string,
    scopes = list(string)
  })
  default = {
    email  = ""
    scopes = ["cloud-platform"]
  }
}

variable "project" {
  type = string
}
