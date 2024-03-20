/**
 * Copyright 2023 Google LLC
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
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

provider "google" {
  alias   = "service_project"
  project = var.project_id_1
  region  = var.region
}

data "template_file" "group-startup-script" {
  template = file(format("%s/gceme.sh.tpl", path.module))

  vars = {
    PROXY_PATH = ""
  }
}

data "google_projects" "service_project" {
  provider = google.service_project
  filter   = "id:${var.project_id_1}"
}

resource "google_project_iam_member" "host_project_network_user" {
  project = var.project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${data.google_projects.service_project.projects[0].number}@cloudservices.gserviceaccount.com"
}

resource "google_compute_network" "default" {
  name                    = var.network_name
  auto_create_subnetworks = "false"
  project                 = var.project_id
}

resource "google_compute_subnetwork" "default" {
  name                     = "${var.network_name}-${var.region}"
  ip_cidr_range            = "10.127.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.region
  project                  = var.project_id
  private_ip_google_access = true
}

resource "google_compute_router" "default" {
  name    = "lb-http-router"
  network = google_compute_network.default.self_link
  region  = var.region
  project = var.project_id
}

module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 5.0"
  router     = google_compute_router.default.name
  project_id = var.project_id
  region     = var.region
  name       = "cloud-nat-lb-http-router"
}

resource "google_compute_shared_vpc_host_project" "host" {
  project = var.project_id
}

resource "google_compute_shared_vpc_service_project" "service" {
  host_project    = google_compute_shared_vpc_host_project.host.project
  service_project = var.project_id_1
}

module "mig_template" {
  source             = "terraform-google-modules/vm/google//modules/instance_template"
  version            = "~> 7.9"
  project_id         = var.project_id_1
  network            = google_compute_network.default.self_link
  subnetwork         = "${var.network_name}-${var.region}"
  subnetwork_project = var.project_id
  service_account = {
    email  = ""
    scopes = ["cloud-platform"]
  }
  name_prefix    = "cross-project-mig"
  startup_script = data.template_file.group-startup-script.rendered
  tags           = ["allow-cross-project-mig"]
  depends_on = [
    google_compute_subnetwork.default,
    google_compute_shared_vpc_service_project.service
  ]
}

module "mig" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "~> 7.9"
  project_id        = var.project_id_1
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
  depends_on = [
    google_compute_subnetwork.default,
    google_compute_shared_vpc_service_project.service
  ]
}
