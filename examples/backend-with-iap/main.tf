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

module "lb-backend-iap" {
  source  = "terraform-google-modules/lb-http/google//modules/backend"
  version = "~> 13.0"

  project_id = var.project_id
  name       = "backend-with-iap"
  iap_config = {
    enable      = true
    iap_members = ["user:test@test.test"]
  }
}

module "lb-frontend" {
  source  = "terraform-google-modules/lb-http/google//modules/frontend"
  version = "~> 13.0"

  project_id    = var.project_id
  name          = "global-lb-fe-bucket"
  url_map_input = module.lb-backend-iap.backend_service_info
}
