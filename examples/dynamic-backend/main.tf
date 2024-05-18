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
  project = var.project
}

provider "google-beta" {
  project = var.project
}

resource "google_compute_managed_ssl_certificate" "frontend" {
  name = "managedcert"

  managed {
    domains = var.domains
  }
}

module "load_balancer" {
  source  = "terraform-google-modules/lb-http/google//modules/dynamic_backends"
  version = "~> 10.0"

  name                        = "dynamic-backend-lb"
  project                     = var.project
  enable_ipv6                 = true
  create_ipv6_address         = true
  http_forward                = false
  http_keep_alive_timeout_sec = 610

  load_balancing_scheme = "EXTERNAL_MANAGED"

  ssl = true
  ssl_certificates = [
    google_compute_managed_ssl_certificate.frontend.self_link
  ]

  backends = {
    default = {
      protocol                        = "HTTPS"
      port                            = 443
      port_name                       = "https"
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
        enable      = true
        sample_rate = 1.0
      }

      # leave blank, NEGs are dynamically added to the lb via autoneg
      groups = []

      iap_config = {
        enable = false
      }
    }
  }
}
