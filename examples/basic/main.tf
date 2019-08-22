/*
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "google_compute_network" "default" {
  name                    = var.network_prefix
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "group1" {
  name                     = "${var.network_prefix}-group1"
  ip_cidr_range            = "10.126.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.group1_region
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "group2" {
  name                     = "${var.network_prefix}-group2"
  ip_cidr_range            = "10.127.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.group2_region
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "lb" {
  name                     = "${var.network_prefix}-lb"
  ip_cidr_range            = "10.128.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = google_compute_subnetwork.group1.region
  private_ip_google_access = true
}

module "gce-lb-http" {
  source            = "../../"
  name              = "${var.network_prefix}-lb"
  project           = var.project
  target_tags       = [
    module.mig1_template.name,
    module.mig2_template.name]
  firewall_networks = [
    google_compute_network.default.name]

  backends = {
    0 = [
      {
        group = module.mig1.instance_group
      },
      {
        group = module.mig2.instance_group
      },
    ]
  }

  backend_params = [
    // health check path, port name, port number, timeout seconds.
    "/,http,80,10",
  ]
}
