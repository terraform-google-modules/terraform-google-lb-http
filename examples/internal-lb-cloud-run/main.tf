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

module "internal-lb-network" {
  source                  = "terraform-google-modules/network/google//modules/vpc"
  version                 = "~> 10.0.0"
  project_id              = var.project_id
  network_name            = "int-lb-network"
  auto_create_subnetworks = false
}

module "internal-lb-subnet" {
  source  = "terraform-google-modules/network/google//modules/subnets"
  version = "~> 10.0.0"

  subnets = [
    {
      subnet_name   = "int-lb-subnet-a"
      subnet_ip     = "10.1.2.0/24"
      subnet_region = "us-east1"
    },
    {
      subnet_name   = "int-lb-proxy-only-subnet-a"
      subnet_ip     = "10.129.0.0/23"
      subnet_region = "us-east1"
      purpose       = "GLOBAL_MANAGED_PROXY"
      role          = "ACTIVE"
    },
    {
      subnet_name   = "int-lb-subnet-b"
      subnet_ip     = "10.1.3.0/24"
      subnet_region = "us-south1"
    },
    {
      subnet_name   = "int-lb-proxy-only-subnet-b",
      subnet_ip     = "10.130.0.0/23"
      subnet_region = "us-south1"
      purpose       = "GLOBAL_MANAGED_PROXY"
      role          = "ACTIVE"
    }
  ]

  network_name = module.internal-lb-network.network_name
  project_id   = var.project_id
  depends_on   = [module.internal-lb-network]
}

module "backend-service-region-a" {
  source                        = "GoogleCloudPlatform/cloud-run/google//modules/v2"
  version                       = "~> 0.16.3"
  project_id                    = var.project_id
  location                      = "us-central1"
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
  location                      = "us-west1"
  service_name                  = "bs-b"
  containers                    = [{ "container_name" = "", "container_image" = "gcr.io/cloudrun/hello" }]
  members                       = ["allUsers"]
  ingress                       = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  cloud_run_deletion_protection = false
  enable_prometheus_sidecar     = false
}

module "internal-lb-http-backend" {
  source  = "terraform-google-modules/lb-http/google//modules/backend"
  version = "~> 12.0"

  project_id            = var.project_id
  name                  = "int-lb-http-backend"
  enable_cdn            = false
  load_balancing_scheme = "INTERNAL_MANAGED"
  locality_lb_policy    = "RANDOM"
  serverless_neg_backends = [
    { region : "us-central1", type : "cloud-run", service_name : module.backend-service-region-a.service_name },
    { region : "us-west1", type : "cloud-run", service_name : module.backend-service-region-b.service_name }
  ]
}

module "internal-lb-http-frontend" {
  source  = "terraform-google-modules/lb-http/google//modules/frontend"
  version = "~> 12.0"

  project_id            = var.project_id
  name                  = "int-lb-http-frontend"
  url_map_input         = module.internal-lb-http-backend.backend_service_info
  network               = module.internal-lb-network.network_name
  load_balancing_scheme = "INTERNAL_MANAGED"
  internal_forwarding_rules_config = [
    {
      "subnetwork" : module.internal-lb-subnet.subnets["us-east1/int-lb-subnet-a"].id
    },
    {
      "subnetwork" : module.internal-lb-subnet.subnets["us-south1/int-lb-subnet-b"].id
    }
  ]
}

resource "google_vpc_access_connector" "internal_lb_vpc_connector" {
  provider       = google-beta
  project        = var.project_id
  name           = "int-lb-vpc-connector"
  region         = "us-east1"
  ip_cidr_range  = "10.8.0.0/28"
  network        = module.internal-lb-network.network_name
  max_throughput = 500
  min_throughput = 300
}

module "frontend-service-a" {
  source       = "GoogleCloudPlatform/cloud-run/google//modules/v2"
  version      = "~> 0.16.3"
  project_id   = var.project_id
  location     = "us-east1"
  service_name = "fs-a"
  containers   = [{ "env_vars" : { "TARGET_IP" : module.internal-lb-http-frontend.ip_address_internal_managed_http[0] }, "ports" = { "container_port" = 80, "name" = "http1" }, "container_name" = "", "container_image" = "gcr.io/design-center-container-repo/redirect-traffic:latest-2002" }]
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
  location     = "us-east1"
  service_name = "fs-b"
  containers   = [{ "env_vars" : { "TARGET_IP" : module.internal-lb-http-frontend.ip_address_internal_managed_http[1] }, "ports" = { "container_port" = 80, "name" = "http1" }, "container_name" = "", "container_image" = "gcr.io/design-center-container-repo/redirect-traffic:latest-2002" }]
  members      = ["allUsers"]
  vpc_access = {
    connector = google_vpc_access_connector.internal_lb_vpc_connector.id
    egress    = "ALL_TRAFFIC"
  }
  ingress                       = "INGRESS_TRAFFIC_ALL"
  cloud_run_deletion_protection = false
  enable_prometheus_sidecar     = false
}
