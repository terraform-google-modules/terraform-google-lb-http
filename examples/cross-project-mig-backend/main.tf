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


# [START cloudloadbalancing_ext_http_gce_shared_vpc]
module "gce-lb-http" {
  source  = "terraform-google-modules/lb-http/google"
  version = "~> 10.0"

  name                  = "ci-crossproject-lb"
  project               = var.project_id
  target_tags           = ["allow-cross-project-mig"]
  firewall_projects     = [var.project_id]
  firewall_networks     = [var.network_name]
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backends = {
    default = {
      project     = var.project_id_1
      protocol    = "HTTP"
      port        = 80
      port_name   = "http"
      timeout_sec = 10
      enable_cdn  = false

      health_check = {
        request_path = "/"
        port         = 80
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          group = module.mig.instance_group
        }
      ]

      iap_config = {
        enable = false
      }
    }
  }
}
# [END cloudloadbalancing_ext_http_gce_shared_vpc]
