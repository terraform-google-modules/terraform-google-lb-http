/**
 * Copyright 2025 Google LLC
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

resource "google_compute_network" "internal_lb_network" {
  name                    = "int-lb-network"
  auto_create_subnetworks = "false"
  project                 = var.project_id
}

resource "google_compute_subnetwork" "internal_lb_subnet_a" {
  name          = "int-lb-subnet-a"
  ip_cidr_range = "10.1.2.0/24"
  network       = google_compute_network.internal_lb_network.id
  region        = var.subnet_region_a
  project       = var.project_id
  depends_on    = [google_compute_network.internal_lb_network]
}

resource "google_compute_subnetwork" "internal_lb_proxy_only_a" {
  name          = "int-lb-proxy-only-subnet-a"
  ip_cidr_range = "10.129.0.0/23"
  network       = google_compute_network.internal_lb_network.id
  purpose       = "GLOBAL_MANAGED_PROXY"
  region        = var.subnet_region_a
  project       = var.project_id
  role          = "ACTIVE"
  depends_on    = [google_compute_network.internal_lb_network]
}

resource "google_compute_subnetwork" "internal_lb_subnet_b" {
  name          = "int-lb-subnet-b"
  ip_cidr_range = "10.1.3.0/24"
  network       = google_compute_network.internal_lb_network.id
  region        = var.subnet_region_b
  project       = var.project_id
  depends_on    = [google_compute_network.internal_lb_network]
}

resource "google_compute_subnetwork" "internal_lb_proxy_only_b" {
  name          = "int-lb-proxy-only-subnet-b"
  ip_cidr_range = "10.130.0.0/23"
  network       = google_compute_network.internal_lb_network.id
  purpose       = "GLOBAL_MANAGED_PROXY"
  region        = var.subnet_region_b
  project       = var.project_id
  role          = "ACTIVE"
  depends_on    = [google_compute_network.internal_lb_network]
}

module "backend-service-region-a" {
  source                        = "GoogleCloudPlatform/cloud-run/google//modules/v2"
  version                       = "~> 0.16.3"
  project_id                    = var.project_id
  location                      = var.backend_region_a
  service_name                  = "bs-a"
  containers                    = [{ "container_name" = "", "container_image" = "gcr.io/cloudrun/hello" }]
  members                       = ["allUsers"]
  ingress                       = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  cloud_run_deletion_protection = false
  enable_prometheus_sidecar     = false
}

module "backend-service-region-b" {
  source                        = "GoogleCloudPlatform/cloud-run/google//modules/v2"
  version                       = "~> 0.16.3"
  project_id                    = var.project_id
  location                      = var.backend_region_b
  service_name                  = "bs-b"
  containers                    = [{ "container_name" = "", "container_image" = "gcr.io/cloudrun/hello" }]
  members                       = ["allUsers"]
  ingress                       = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  cloud_run_deletion_protection = false
  enable_prometheus_sidecar     = false
}

module "internal-lb-http-backend" {
  source = "../../modules/backend" # use registry 
  #version = "~> 12.1.1"

  project_id            = var.project_id
  name                  = "int-lb-http-backend"
  enable_cdn            = false
  load_balancing_scheme = "INTERNAL_MANAGED"
  locality_lb_policy    = "RANDOM"
  compression_mode      = "DISABLED"
  serverless_neg_backends = [
    { region : var.backend_region_a, type : "cloud-run", service_name : module.backend-service-region-a.service_name },
    { region : var.backend_region_b, type : "cloud-run", service_name : module.backend-service-region-b.service_name }
  ]
}

module "internal-lb-http-frontend" {
  source = "../../modules/frontend" # use registry
  #version = "~> 12.1.1"

  project_id            = var.project_id
  name                  = "int-lb-http-frontend"
  url_map_input         = module.internal-lb-http-backend.backend_service_info
  network               = google_compute_network.internal_lb_network.name
  load_balancing_scheme = "INTERNAL_MANAGED"
  internal_forwarding_rule_subnetworks = [
    google_compute_subnetwork.internal_lb_subnet_a.id,
    google_compute_subnetwork.internal_lb_subnet_b.id
  ]
  #depends_on = [google_compute_subnetwork.internal_lb_proxy_only_a, google_compute_subnetwork.internal_lb_proxy_only_b, google_compute_subnetwork.internal_lb_subnet_a, google_compute_network.internal_lb_subnet_b]
}

resource "google_vpc_access_connector" "internal_lb_vpc_connector" {
  provider       = google-beta
  project        = var.project_id
  name           = "int-lb-vpc-connector"
  region         = var.subnet_region_a
  ip_cidr_range  = "10.8.0.0/28"
  network        = google_compute_network.internal_lb_network.name
  max_throughput = 500
  min_throughput = 300
}

module "frontend-service-a" {
  source       = "GoogleCloudPlatform/cloud-run/google//modules/v2"
  version      = "~> 0.16.3"
  project_id   = var.project_id
  location     = var.subnet_region_a
  service_name = "fs-a"
  containers   = [{ "env_vars" : { "TARGET_IP" : module.internal-lb-http-frontend.ip_address_http_internal_managed[0] }, "ports" = { "container_port" = 80, "name" = "http1" }, "container_name" = "", "container_image" = "gcr.io/design-center-container-repo/redirect-traffic:latest-2002" }]
  members      = ["allUsers"]
  vpc_access = {
    connector = google_vpc_access_connector.internal_lb_vpc_connector.id
    egress    = "ALL_TRAFFIC"
  }
  ingress                       = "INGRESS_TRAFFIC_ALL"
  cloud_run_deletion_protection = false
  enable_prometheus_sidecar     = false
  depends_on                    = [google_vpc_access_connector.internal_lb_vpc_connector]
}

module "frontend-service-b" {
  source       = "GoogleCloudPlatform/cloud-run/google//modules/v2"
  version      = "~> 0.16.3"
  project_id   = var.project_id
  location     = var.subnet_region_a
  service_name = "fs-b"
  containers   = [{ "env_vars" : { "TARGET_IP" : module.internal-lb-http-frontend.ip_address_http_internal_managed[1] }, "ports" = { "container_port" = 80, "name" = "http1" }, "container_name" = "", "container_image" = "gcr.io/design-center-container-repo/redirect-traffic:latest-2002" }]
  members      = ["allUsers"]
  vpc_access = {
    connector = google_vpc_access_connector.internal_lb_vpc_connector.id
    egress    = "ALL_TRAFFIC"
  }
  ingress                       = "INGRESS_TRAFFIC_ALL"
  cloud_run_deletion_protection = false
  enable_prometheus_sidecar     = false
}
