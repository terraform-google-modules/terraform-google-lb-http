/**
 * Copyright 2022 Google LLC
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

provider "google" {
  project = var.project_id
}

provider "google-beta" {
  project = var.project_id
}

resource "google_compute_network" "default" {
  name                    = var.network_name
  auto_create_subnetworks = true
}

module "load_balancer" {
  source  = "terraform-google-modules/lb-http/google"
  version = "~> 10.0"

  name           = "traffic-director-lb"
  project        = var.project_id
  create_address = false

  load_balancing_scheme = "INTERNAL_SELF_MANAGED"
  network               = google_compute_network.default.self_link
  address               = "0.0.0.0"
  firewall_networks     = []

  backends = {
    default = {
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = 30
      connection_draining_timeout_sec = 0
      enable_cdn                      = false

      health_check = {
        check_interval_sec  = 15
        timeout_sec         = 15
        healthy_threshold   = 4
        unhealthy_threshold = 4
        request_path        = "/api/health"
        port                = 443
        logging             = true
      }

      log_config = {
        enable = false
      }

      # leave blank, NEGs are dynamically added to the lb via autoneg
      groups = []

      iap_config = {
        enable = false
      }
    }
  }
}
