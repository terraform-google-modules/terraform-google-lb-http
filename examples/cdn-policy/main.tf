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
  version    = "~> 2.2"
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
  source            = "../../"
  name              = "mig-http-lb"
  project           = var.project_id
  target_tags       = [google_compute_network.default.name]
  firewall_networks = [google_compute_network.default.name]


  backends = {
    default = {
      description                     = null
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = 10
      connection_draining_timeout_sec = null
      enable_cdn                      = true
      compression_mode                = null
      edge_security_policy            = null
      security_policy                 = null
      session_affinity                = null
      affinity_cookie_ttl_sec         = null
      custom_request_headers          = null
      custom_response_headers         = null

      health_check = {
        check_interval_sec  = null
        timeout_sec         = null
        healthy_threshold   = null
        unhealthy_threshold = null
        request_path        = "/"
        port                = 80
        host                = null
        logging             = null
      }

      log_config = {
        enable      = false
        sample_rate = null
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
      }

      groups = [
        {
          group                        = module.mig.instance_group
          balancing_mode               = null
          capacity_scaler              = null
          description                  = null
          max_connections              = null
          max_connections_per_instance = null
          max_connections_per_endpoint = null
          max_rate                     = null
          max_rate_per_instance        = null
          max_rate_per_endpoint        = null
          max_utilization              = null
        }
      ]

      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }
    }
  }
}
