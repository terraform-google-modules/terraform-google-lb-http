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

provider "google" {
  project = var.project
}

provider "google-beta" {
  project = var.project
}

resource "google_compute_network" "default" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name                     = var.network_name
  ip_cidr_range            = "10.127.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.region
  private_ip_google_access = true
}

resource "google_compute_router" "default" {
  name    = "lb-http-router"
  network = google_compute_network.default.self_link
  region  = var.region
}

module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 2.2"
  router     = google_compute_router.default.name
  project_id = var.project
  region     = var.region
  name       = "cloud-nat-lb-http-router"
}

data "template_file" "group-startup-script" {
  template = file(format("%s/gceme.sh.tpl", path.module))

  vars = {
    PROXY_PATH = ""
  }
}

module "mig_template" {
  source     = "terraform-google-modules/vm/google//modules/instance_template"
  version    = "~> 7.9"
  network    = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.default.self_link
  service_account = {
    email  = ""
    scopes = ["cloud-platform"]
  }
  name_prefix    = var.network_name
  startup_script = data.template_file.group-startup-script.rendered
  tags = [
    var.network_name,
    module.cloud-nat.router_name
  ]
}

module "mig" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "~> 7.9"
  instance_template = module.mig_template.self_link
  region            = var.region
  hostname          = var.network_name
  target_size       = 2
  named_ports = [{
    name = "http",
    port = 80
  }]
  network    = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.default.self_link
}

module "gce-lb-http" {
  source            = "terraform-google-modules/lb-http/google"
  version           = "~> 10.0"
  name              = "mig-http-lb"
  project           = var.project
  target_tags       = [var.network_name]
  firewall_networks = [google_compute_network.default.name]


  backends = {
    default = {
      protocol    = "HTTP"
      port        = 80
      port_name   = "http"
      timeout_sec = 10
      enable_cdn  = false

      health_check = {
        request_path = "/"
        port         = 80
      }

      log_config = {
        enable = false
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
