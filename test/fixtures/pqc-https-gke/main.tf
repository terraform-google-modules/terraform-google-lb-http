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

resource "random_id" "random_suffix" {
  byte_length = 2
}

locals {
  name_prefix = "pqc-test-${random_id.random_suffix.hex}"
}

resource "google_compute_network" "default" {
  name                    = local.name_prefix
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "default" {
  name                     = local.name_prefix
  ip_cidr_range            = "10.127.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.region
  project                  = var.project_id
  private_ip_google_access = true
}

module "mig_template" {
  source     = "terraform-google-modules/vm/google//modules/instance_template"
  version    = "~> 15.0"
  project_id = var.project_id
  region     = var.region
  network    = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.default.self_link
  service_account = {
    email  = ""
    scopes = ["cloud-platform"]
  }
  name_prefix          = local.name_prefix
  source_image_family  = "ubuntu-2204-lts"
  source_image_project = "ubuntu-os-cloud"
}

module "mig" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "~> 15.0"
  project_id        = var.project_id
  instance_template = module.mig_template.self_link
  region            = var.region
  hostname          = local.name_prefix
  target_size       = 1
  named_ports = [{
    name = "http",
    port = 80
  }]
}

module "example" {
  source = "../../../examples/pqc-https-gke"

  project           = var.project_id
  name              = local.name_prefix
  network_name      = google_compute_network.default.name
  backend           = module.mig.instance_group
  service_port      = 80
  service_port_name = "http"
  target_tags       = local.name_prefix
}
