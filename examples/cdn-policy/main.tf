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

locals {
  region = "us-west1"
}

resource "google_compute_network" "default" {
  name                    = "tf-lb-http-cdn"
  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name                     = google_compute_network.default.name
  project                  = var.project_id
  ip_cidr_range            = "10.127.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = local.region
  private_ip_google_access = true
}

resource "google_compute_router" "default" {
  name    = "lb-http-router"
  project = var.project_id
  network = google_compute_network.default.self_link
  region  = local.region
}

module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 5.0"
  router     = google_compute_router.default.name
  project_id = var.project_id
  region     = local.region
  name       = "cloud-nat-lb-http-router"
}

module "mig_template" {
  source     = "terraform-google-modules/vm/google//modules/instance_template"
  version    = "~> 8.0"
  network    = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.default.self_link
  project_id = var.project_id
  service_account = {
    email  = ""
    scopes = ["cloud-platform"]
  }
  name_prefix    = google_compute_network.default.name
  startup_script = templatefile("${path.module}/gceme.sh.tpl", { PROXY_PATH = "" })
  tags = [
    google_compute_network.default.name,
    module.cloud-nat.router_name
  ]
}

module "mig" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "~> 8.0"
  project_id        = var.project_id
  instance_template = module.mig_template.self_link
  region            = local.region
  hostname          = google_compute_network.default.name
  target_size       = 2
  named_ports = [{
    name = "http",
    port = 80
  }]
}

module "gce-lb-http" {
  source  = "terraform-google-modules/lb-http/google"
  version = "~> 10.0"

  name              = "mig-http-lb"
  project           = var.project_id
  target_tags       = [google_compute_network.default.name]
  firewall_networks = [google_compute_network.default.name]


  backends = {
    default = {
      protocol    = "HTTP"
      port_name   = "http"
      timeout_sec = 10
      enable_cdn  = true

      health_check = {
        request_path = "/"
        port         = 80
      }

      log_config = {
        enable = false
      }

      cdn_policy = {
        cache_mode  = "CACHE_ALL_STATIC"
        default_ttl = 3600
        client_ttl  = 7200
        max_ttl     = 10800
        cache_key_policy = {
          include_host          = true
          include_protocol      = true
          include_query_string  = true
          include_named_cookies = ["__next_preview_data", "__prerender_bypass"]
        }
        bypass_cache_on_request_headers = ["example-header-1", "example-header-2"]
      }

      groups = [
        {
          group = module.mig.instance_group
        }
      ]

      iap_config = {
        enable = false
      }
    }
  }
}
