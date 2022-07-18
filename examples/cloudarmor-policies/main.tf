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

module "cloud_armor_security_policies" {
  source  = "../../modules/cloudarmor_policies"
  project = var.project_id

  name        = "tf-managed-policy-01"
  description = "CloudArmor policy"

  rules = [{
    action         = "deny(404)" #Deny by default policy
    type           = "CLOUD_ARMOR_EDGE"
    priority       = "2147483647"
    versioned_expr = "SRC_IPS_V1"
    config = [{
      src_ip_ranges = ["*"]
    }]
    description = "Default rule, higher priority overrides it."
    },
    {
      action         = "allow"
      priority       = "1000"
      versioned_expr = "SRC_IPS_V1"
      config = [{
        src_ip_ranges = ["127.0.0.1"]
      }]
      description = "Allow traffic only from specific sources."
  }]
}

# GCE LB test config
resource "google_compute_network" "default" {
  name                    = var.network_prefix
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "group1" {
  name                     = "${var.network_prefix}-group1"
  ip_cidr_range            = "10.126.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.group1_region
  private_ip_google_access = true
}

# Router and Cloud NAT are required for installing packages from repos (apache, php etc)
resource "google_compute_router" "group1" {
  name    = "${var.network_prefix}-gw-group1"
  network = google_compute_network.default.self_link
  region  = var.group1_region
}

module "cloud-nat-group1" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "1.4.0"
  router     = google_compute_router.group1.name
  project_id = var.project_id
  region     = var.group1_region
  name       = "${var.network_prefix}-cloud-nat-group1"
}

resource "google_compute_subnetwork" "group2" {
  name                     = "${var.network_prefix}-group2"
  ip_cidr_range            = "10.127.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.group2_region
  private_ip_google_access = true
}

resource "google_compute_firewall" "default" {
  name    = "allow-80"
  network = google_compute_network.default.name
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

# Router and Cloud NAT are required for installing packages from repos (apache, php etc)
resource "google_compute_router" "group2" {
  name    = "${var.network_prefix}-gw-group2"
  network = google_compute_network.default.self_link
  region  = var.group2_region
}

module "cloud-nat-group2" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "1.4.0"
  router     = google_compute_router.group2.name
  project_id = var.project_id
  region     = var.group2_region
  name       = "${var.network_prefix}-cloud-nat-group2"
}


module "gce-lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google"
  version = "~> 5.1"
  name    = var.network_prefix
  project = var.project_id
  target_tags = [
    "${var.network_prefix}-group1",
    module.cloud-nat-group1.router_name,
    "${var.network_prefix}-group2",
    module.cloud-nat-group2.router_name
  ]
  firewall_networks = [google_compute_network.default.name]

  backends = {
    default = {

      description                     = null
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = 10
      connection_draining_timeout_sec = null
      enable_cdn                      = false
      security_policy                 = "projects/${var.project_id}/global/securityPolicies/tf-managed-policy-01"
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
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          group                        = module.mig1.instance_group
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
        },
        {
          group                        = module.mig2.instance_group
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
        },
      ]

      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }
    }
  }

  depends_on = [
    module.cloud_armor_security_policies
  ]
}
