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
  profile                   = "RESTRICTED"
  post_quantum_key_exchange = "ENABLED"
  min_tls_version           = "TLS_1_3"
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


  url_map        = google_compute_url_map.main.self_link
  create_url_map = false

  backends = {
    default = {
      protocol    = "HTTP"
      port        = var.service_port
      port_name   = var.service_port_name
      timeout_sec = 10
      enable_cdn  = false

      health_check = {
        request_path = "/"
        port         = var.service_port
        logging      = true
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          group = var.backend
        },
      ]
    }
  }
}

resource "google_compute_url_map" "main" {
  name            = var.name
  default_service = module.gce_lb_https.backend_services["default"].self_link

  host_rule {
    # Note: In production environments, using a wildcard "*" is discouraged.
    # The exact domain/host (e.g., "pqc.example.com") should be explicitly defined here.
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
  prefix      = "${var.project}-lb-assets-"
  byte_length = 2
}

resource "google_storage_bucket" "assets" {
  name     = random_id.assets_bucket.hex
  location = var.location

  force_destroy = true

  uniform_bucket_level_access = true
}

resource "google_compute_backend_bucket" "assets" {
  name        = google_storage_bucket.assets.name
  description = "Contains static resources for a quantum resistance HTTPS load balancer example app"
  bucket_name = google_storage_bucket.assets.name
  enable_cdn  = true
}

resource "google_storage_bucket_object" "image" {
  name         = "assets/gcp-logo.svg"
  content      = file("${path.module}/gcp-logo.svg")
  content_type = "image/svg+xml"
  bucket       = google_storage_bucket.assets.name
}

resource "google_storage_bucket_iam_member" "public" {
  bucket = google_storage_bucket.assets.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
