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
}
 
provider "google-beta" {
  project = var.project_id
}

# [START cloudloadbalancing_ext_http_cloudrun]
module "lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "~> 6.3"
  name    = var.lb_name
  project = var.project_id
  url_map           = google_compute_url_map.custommap.self_link
  create_url_map    = true
  ssl                             = true
  managed_ssl_certificate_domains = [var.domain]
  https_redirect                  = var.ssl
  labels                          = { "example-label" = "cloudrun-urlmap-example" }
 
  backends = {
    app1backend = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.serverless_neg1.id
        }
      ]
      enable_cdn              = false
      security_policy         = null
      custom_request_headers  = null
      custom_response_headers = null
      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }
      log_config = {
        enable      = false
        sample_rate = null
      }
      protocol         = "HTTP"
      port_name        = null
      compression_mode = null
    }
 
    app2backend = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.serverless_neg2.id
        }
      ]
      enable_cdn              = false
      security_policy         = null
      custom_request_headers  = null
      custom_response_headers = null
 
      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }
      log_config = {
        enable      = false
        sample_rate = null
      }
      protocol         = null
      port_name        = null
      compression_mode = null
    }
  }
}
 
resource "google_compute_url_map" "custommap" {
  // note that this is the name of the load balancer
  name            = var.lb_name
  default_service = module.lb-http.backend_services["app1backend"].self_link
 
  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
 
  path_matcher {
    name            = "allpaths"
    default_service = module.lb-http.backend_services["app1backend"].self_link
 
    path_rule {
      paths = [
        "/app1",
        "/app1/*"
      ]
      service = module.lb-http.backend_services["app1backend"].self_link
    }
 
    path_rule {
      paths = [
        "/app2",
        "/app2/*"
      ]
      service = module.lb-http.backend_services["app2backend"].self_link
    }
  }
}
 
resource "google_compute_region_network_endpoint_group" "serverless_neg1" {
  provider              = google-beta
  name                  = "serverless-neg1"
  network_endpoint_type = "SERVERLESS"
  region                = "us-central1"
  cloud_run {
    service = google_cloud_run_service.app1.name
  }
}
 
resource "google_compute_region_network_endpoint_group" "serverless_neg2" {
  provider              = google-beta
  name                  = "serverless-neg2"
  network_endpoint_type = "SERVERLESS"
  region                = "us-central1"
  cloud_run {
    service = google_cloud_run_service.app2.name
  }
}
 
resource "google_cloud_run_service" "app1" {
  name     = "app1cloudrun"
  location = "us-central1"
  project  = var.project_id
 
  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
      }
    }
  }
  metadata {
    annotations = {
      # For valid annotation values and descriptions, see
      # https://cloud.google.com/sdk/gcloud/reference/run/deploy#--ingress
      "run.googleapis.com/ingress" = "all"
    }
  }
}
 
resource "google_cloud_run_service" "app2" {
  name     = "app2cloudrun"
  location = "us-central1"
  project  = var.project_id
 
  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
      }
    }
  }
  metadata {
    annotations = {
      # For valid annotation values and descriptions, see
      # https://cloud.google.com/sdk/gcloud/reference/run/deploy#--ingress
      "run.googleapis.com/ingress" = "all"
    }
  }
}
 
resource "google_cloud_run_service_iam_member" "public-access-app1" {
  location = google_cloud_run_service.app1.location
  project  = google_cloud_run_service.app1.project
  service  = google_cloud_run_service.app1.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "public-access-app2" {
  location = google_cloud_run_service.app2.location
  project  = google_cloud_run_service.app2.project
  service  = google_cloud_run_service.app2.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
# [END cloudloadbalancing_ext_http_cloudrun]