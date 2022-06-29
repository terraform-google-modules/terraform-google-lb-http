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
  source     = "../../modules/cloudarmor_policies"
  project_id = var.project_id

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

module "lb-http" {

  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "6.2.0"
  name    = "cloud-armor-test-gclb"
  project = var.project_id

  ssl            = false
  https_redirect = false

  backends = {
    default = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.serverless_neg.id
        }
      ]
      enable_cdn              = false
      security_policy         = "projects/${var.project_id}/global/securityPolicies/tf-managed-policy-01"
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
    }
  }
  depends_on = [
    module.cloud_armor_security_policies
  ]
}

resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  provider              = google-beta
  name                  = "serverless-neg"
  network_endpoint_type = "SERVERLESS"
  region                = "us-central1"
  cloud_run {
    service = google_cloud_run_service.default.name
  }
}

resource "google_cloud_run_service" "default" {
  name     = "example"
  location = "us-central1"
  project  = var.project_id

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
      }
    }
  }
}

resource "google_cloud_run_service_iam_member" "public-access" {
  location = google_cloud_run_service.default.location
  project  = google_cloud_run_service.default.project
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
