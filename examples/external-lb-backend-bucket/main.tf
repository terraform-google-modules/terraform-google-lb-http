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

module "lb-frontend" {
  source  = "terraform-google-modules/lb-http/google//modules/frontend"
  version = "~> 12.0"

  project_id    = var.project_id
  name          = "global-lb-fe-bucket"
  url_map_input = module.lb-backend.backend_service_info
}

module "lb-backend" {
  source  = "terraform-google-modules/lb-http/google//modules/backend"
  version = "~> 12.0"

  project_id          = var.project_id
  name                = "global-lb-be-bucket"
  backend_bucket_name = module.gcs.name
  enable_cdn          = true
}

module "gcs" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 12.0"

  project_id    = var.project_id
  location      = "us-central1"
  name          = "gcs-bucket"
  force_destroy = true
  iam_members   = [{ member = "allUsers", role = "roles/storage.objectViewer" }]
}

// The image object in Cloud Storage.
// Note that the path in the bucket matches the paths in the url map path rule above.
resource "google_storage_bucket_object" "image" {
  name         = "assets/gcp-logo.svg"
  content      = file("./gcp-logo.svg")
  content_type = "image/svg+xml"
  bucket       = module.gcs.name
}
