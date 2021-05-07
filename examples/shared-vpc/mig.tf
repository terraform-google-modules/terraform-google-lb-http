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

data "template_file" "group-startup-script" {
  template = file(format("%s/gceme.sh.tpl", path.module))

  vars = {
    PROXY_PATH = ""
  }
}

resource "google_compute_network" "default" {
  name                    = var.network
  auto_create_subnetworks = "false"
  project                 = var.host_project
}

resource "google_compute_subnetwork" "default" {
  name                     = var.subnetwork
  ip_cidr_range            = "10.127.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.region
  project                  = var.host_project
  private_ip_google_access = true
}

resource "google_compute_router" "default" {
  name    = "lb-http-router"
  network = google_compute_network.default.self_link
  region  = var.region
  project = var.host_project
}

module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "1.0.0"
  router     = google_compute_router.default.name
  project_id = var.host_project
  region     = var.region
  name       = "cloud-nat-lb-http-router"
}

module "mig_template" {
  source             = "terraform-google-modules/vm/google//modules/instance_template"
  version            = "6.2.0"
  network            = google_compute_network.default.self_link
  subnetwork         = var.subnetwork
  subnetwork_project = var.host_project
  service_account = {
    email  = ""
    scopes = ["cloud-platform"]
  }
  name_prefix    = "shared-vpc-mig"
  startup_script = data.template_file.group-startup-script.rendered
  tags           = ["allow-shared-vpc-mig"]
}

module "mig" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "6.2.0"
  instance_template = module.mig_template.self_link
  region            = var.region
  hostname          = var.network
  target_size       = 2
  named_ports = [{
    name = "http",
    port = 80
  }]
  network    = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.default.self_link
}
