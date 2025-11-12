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
  network_name            = "int-lb-mig-network"
  auto_create_subnetworks = false
}

module "internal-lb-subnet" {
  source  = "terraform-google-modules/network/google//modules/subnets"
  version = "~> 10.0.0"

  subnets = [
    {
      subnet_name   = "int-lb-mig-subnet-a"
      subnet_ip     = "10.1.2.0/24"
      subnet_region = "us-east1"
    },
    {
      subnet_name   = "int-lb-mig-proxy-only-subnet-a"
      subnet_ip     = "10.129.0.0/23"
      subnet_region = "us-east1"
      purpose       = "GLOBAL_MANAGED_PROXY"
      role          = "ACTIVE"
    },
    {
      subnet_name   = "int-lb-mig-subnet-b"
      subnet_ip     = "10.1.3.0/24"
      subnet_region = "us-central1"
    },
    {
      subnet_name   = "int-lb-mig-proxy-only-subnet-b",
      subnet_ip     = "10.130.0.0/23"
      subnet_region = "us-central1"
      purpose       = "GLOBAL_MANAGED_PROXY"
      role          = "ACTIVE"
    }
  ]

  network_name = module.internal-lb-network.network_name
  project_id   = var.project_id
  depends_on   = [module.internal-lb-network]
}

module "instance-template-region-a" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "~> 13.0"

  project_id           = var.project_id
  region               = "us-east1"
  source_image_project = "debian-cloud"
  source_image         = "debian-12"
  network              = module.internal-lb-network.network_name
  subnetwork           = module.internal-lb-subnet.subnets["us-east1/int-lb-mig-subnet-a"].name
  access_config        = [{ network_tier : "PREMIUM" }]
  name_prefix          = "instance-template-region-a"
  startup_script       = <<EOF
    #! /bin/bash
    sudo apt-get update
    sudo apt-get install apache2 -y
    sudo a2ensite default-ssl
    sudo a2enmod ssl
    vm_hostname="$(curl -H "Metadata-Flavor:Google" \
    http://169.254.169.254/computeMetadata/v1/instance/name)"
    sudo echo "Page served from: $vm_hostname" | \
    tee /var/www/html/index.html
    sudo systemctl restart apache2
    EOF
  tags = [
    "load-balanced-backend"
  ]
}

module "instance-template-region-b" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "~> 13.0"

  project_id           = var.project_id
  region               = "us-central1"
  source_image_project = "debian-cloud"
  source_image         = "debian-12"
  network              = module.internal-lb-network.network_name
  subnetwork           = module.internal-lb-subnet.subnets["us-central1/int-lb-mig-subnet-b"].name
  access_config        = [{ network_tier : "PREMIUM" }]
  name_prefix          = "instance-template-region-b"
  startup_script       = <<EOF
    #! /bin/bash
    sudo apt-get update
    sudo apt-get install apache2 -y
    sudo a2ensite default-ssl
    sudo a2enmod ssl
    vm_hostname="$(curl -H "Metadata-Flavor:Google" \
    http://169.254.169.254/computeMetadata/v1/instance/name)"
    sudo echo "Page served from: $vm_hostname" | \
    tee /var/www/html/index.html
    sudo systemctl restart apache2
    EOF
  tags = [
    "load-balanced-backend"
  ]
}

module "mig-region-a" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "~> 13.0"
  instance_template = module.instance-template-region-a.self_link
  project_id        = var.project_id
  region            = "us-east1"
  hostname          = "mig-group-region-a"
  target_size       = 2
  named_ports = [{
    name = "http",
    port = 80
  }]
  depends_on = [module.instance-template-region-a]
}

module "mig-region-b" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "~> 13.0"
  instance_template = module.instance-template-region-b.self_link
  project_id        = var.project_id
  region            = "us-central1"
  hostname          = "mig-group-region-b"
  target_size       = 2
  named_ports = [{
    name = "http",
    port = 80
  }]
  depends_on = [module.instance-template-region-b]
}

module "internal-lb-http-backend" {
  source  = "terraform-google-modules/lb-http/google//modules/backend"
  version = "~> 0.4.0"

  project_id            = var.project_id
  name                  = "int-lb-mig-http-backend"
  enable_cdn            = false
  load_balancing_scheme = "INTERNAL_MANAGED"
  groups = [
    {
      group : module.mig-region-a.instance_group,
    },
    {
      group : module.mig-region-b.instance_group,
    }
  ]
  health_check = {
    protocol : "HTTP",
    port_specification = "USE_SERVING_PORT"
    proxy_header       = "NONE"
    request_path       = "/"
  }
  firewall_networks = [module.internal-lb-network.network_name]
  firewall_source_ranges = [
    "10.129.0.0/23",
    "10.130.0.0/23"
  ]
  target_tags = [
    "load-balanced-backend"
  ]
}

module "internal-lb-http-frontend" {
  source  = "terraform-google-modules/lb-http/google//modules/frontend"
  version = "~> 13.0"

  project_id            = var.project_id
  name                  = "int-lb-mig-http-frontend"
  url_map_input         = module.internal-lb-http-backend.backend_service_info
  network               = module.internal-lb-network.network_name
  load_balancing_scheme = "INTERNAL_MANAGED"
  internal_forwarding_rules_config = [
    {
      "region" : "us-east1",
      "subnetwork" : module.internal-lb-subnet.subnets["us-east1/int-lb-mig-subnet-a"].id
    },
    {
      "region" : "us-central1",
      "subnetwork" : module.internal-lb-subnet.subnets["us-central1/int-lb-mig-subnet-b"].id
    }
  ]
}

resource "google_vpc_access_connector" "internal_lb_vpc_connector" {
  provider       = google-beta
  project        = var.project_id
  name           = "fe-vpc-cx-gce"
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
  service_name = "fs-gce-a"
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
  service_name = "fs-gce-b"
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

