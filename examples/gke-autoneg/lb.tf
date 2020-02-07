/**
 * Copyright 2020 Google LLC
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


module "lb-http" {
  source = "../../modules/dynamic_backends"

  project     = var.project_id
  name        = "gke-http-lb"
  target_tags = ["gke-gke-cluster-dev"]

  firewall_projects = [var.network_project]
  firewall_networks = [var.network_name]

  backends = {
    default = {
      description = "GKE instances"
      protocol    = "HTTP"
      port        = 80
      port_name   = "http"

      timeout_sec                     = 10
      connection_draining_timeout_sec = null
      enable_cdn                      = false
      affinity_cookie_ttl_sec         = null
      session_affinity                = null
      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      health_check = {
        request_path = "/"
        host         = null
        port         = 80
        protocol     = "HTTP"
        logging      = true

        check_interval_sec  = 1
        timeout_sec         = 1
        healthy_threshold   = 1
        unhealthy_threshold = null
      }

      groups = []
    }
  }
}
