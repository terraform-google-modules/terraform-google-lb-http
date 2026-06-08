/**
 * Copyright 2026 Google LLC
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

data "google_client_config" "current" {}

resource "google_compute_ssl_policy" "main" {
  name                      = "${var.name}-pqc-policy"
  profile                   = "MODERN"
  post_quantum_key_exchange = "ENABLED"
  min_tls_version           = "TLS_1_2"
}


module "gce_lb_https" {
  source  = "terraform-google-modules/lb-http/google"
  version = "~> 14.0"

  project                = var.project
  name                   = var.name
  ssl                    = true
  create_ssl_certificate = true
  private_key            = tls_private_key.example.private_key_pem
  certificate            = tls_self_signed_cert.example.cert_pem
  firewall_networks      = [var.network_name]
  ssl_policy             = google_compute_ssl_policy.main.id

  target_tags = [var.target_tags]


  url_map        = google_compute_url_map.my_url_map.self_link
  create_url_map = false

  backends = {
    default = {
      description                     = null
      protocol                        = "HTTP"
      port                            = var.service_port
      port_name                       = var.service_port_name
      timeout_sec                     = 10
      connection_draining_timeout_sec = null
      enable_cdn                      = false
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
        port                = var.service_port
        host                = null
        logging             = true
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          # Each node pool instance group should be added to the backend.
          group                        = var.backend
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

}

resource "google_compute_url_map" "my_url_map" {
  name            = var.name
  default_service = module.gce_lb_https.backend_services["default"].self_link

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = module.gce_lb_https.backend_services["default"].self_link

    path_rule {
      paths = [
        "/assets",
        "/assets/*"
      ]
      service = google_compute_backend_bucket.assets.self_link
    }
  }
}

resource "random_id" "assets_bucket" {
  prefix      = "${data.google_client_config.current.project}-lb-assets-"
  byte_length = 2
}

resource "google_compute_backend_bucket" "assets" {
  name        = random_id.assets_bucket.hex
  description = "Contains static resources for example app"
  bucket_name = google_storage_bucket.assets.name
  enable_cdn  = true
}

resource "google_storage_bucket" "assets" {
  name     = random_id.assets_bucket.hex
  location = "US"

  force_destroy = true

  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "image" {
  name         = "assets/gcp-logo.svg"
  content      = file("${path.module}/gcp-logo.svg")
  content_type = "image/svg+xml"
  bucket       = google_storage_bucket.assets.name
}

resource "google_storage_bucket_iam_member" "public" {
  bucket = google_storage_bucket.assets.name
  role   = "roles/storage.viewer"
  member = "allUsers"
}
