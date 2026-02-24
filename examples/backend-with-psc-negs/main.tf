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


module "producer-network" {
  source                  = "terraform-google-modules/network/google//modules/vpc"
  version                 = "~> 10.0.0"
  project_id              = var.project_id
  network_name            = "producer-network"
  auto_create_subnetworks = false
}

module "producer-subnet" {
  source  = "terraform-google-modules/network/google//modules/subnets"
  version = "~> 10.0.0"

  subnets = [
    {
      subnet_name   = "producer-subnet-a"
      subnet_ip     = "10.1.2.0/24"
      subnet_region = "us-central1"
    },
    {
      subnet_name   = "producer-subnet-b"
      subnet_ip     = "10.1.3.0/24"
      subnet_region = "us-central1"
      purpose       = "PRIVATE_SERVICE_CONNECT"
    }
  ]

  network_name = module.producer-network.network_name
  project_id   = var.project_id
  depends_on   = [module.producer-network]
}

module "gce-ilb" {
  source  = "GoogleCloudPlatform/lb-internal/google"
  version = "~> 8.0"
  project = var.project_id
  region  = "us-central1"
  name    = "group2-ilb"
  ports   = ["80"]

  source_tags = ["allow-group1"]
  target_tags = ["allow-group2"]

  global_access = true

  network    = module.producer-network.network_name
  subnetwork = module.producer-subnet.subnets["us-central1/producer-subnet-a"].name

  health_check = {
    type                = "http"
    check_interval_sec  = 1
    healthy_threshold   = 4
    timeout_sec         = 1
    unhealthy_threshold = 5
    response            = ""
    proxy_header        = "NONE"
    port                = 80
    port_name           = "health-check-port"
    request             = ""
    request_path        = "/"
    host                = "1.2.3.4"
    enable_log          = false
  }

  backends   = []
  depends_on = [module.producer-subnet]

}

resource "google_compute_service_attachment" "minimal_sa" {
  project               = var.project_id
  name                  = "sa"
  region                = "us-central1"
  enable_proxy_protocol = false
  connection_preference = "ACCEPT_AUTOMATIC"
  nat_subnets           = [module.producer-subnet.subnets["us-central1/producer-subnet-b"].name]
  target_service        = module.gce-ilb.forwarding_rule

  depends_on = [module.gce-ilb]
}


module "psc-neg-network" {
  source                  = "terraform-google-modules/network/google//modules/vpc"
  version                 = "~> 10.0.0"
  project_id              = var.project_id
  network_name            = "psc-neg-network"
  auto_create_subnetworks = false
}

module "psc-neg-subnet" {
  source  = "terraform-google-modules/network/google//modules/subnets"
  version = "~> 10.0.0"

  subnets = [
    {
      subnet_name   = "psc-neg-subnet-a"
      subnet_ip     = "10.1.2.0/24"
      subnet_region = "us-central1"
    }
  ]

  network_name = module.psc-neg-network.network_name
  project_id   = var.project_id
  depends_on   = [module.psc-neg-network]
}

module "lb-backend-psc-neg" {
  source  = "terraform-google-modules/lb-http/google//modules/backend"
  version = "~> 12.0"

  project_id = var.project_id
  name       = "backend-with-psc-negs"
  psc_neg_backends = [{
    name               = "test-psc-1"
    region             = "us-central1"
    psc_target_service = google_compute_service_attachment.minimal_sa.self_link
    network            = module.psc-neg-network.network_name
    subnetwork         = module.psc-neg-subnet.subnets["us-central1/psc-neg-subnet-a"].name
    producer_port      = "80"
  }]

  depends_on = [google_compute_service_attachment.minimal_sa]
}

module "lb-frontend" {
  source  = "terraform-google-modules/lb-http/google//modules/frontend"
  version = "~> 12.0"

  project_id    = var.project_id
  name          = "global-lb-fe-psc-neg"
  url_map_input = module.lb-backend-psc-neg.backend_service_info
}
