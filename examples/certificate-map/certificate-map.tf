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

locals {
  cert_map_name = "projects/${var.project_id}/locations/global/certificateMaps/certmgr-map"
}

resource "google_certificate_manager_certificate" "all" {
  name        = "certmgr-cert"
  description = "The default cert for all domains"
  project     = var.project_id
  managed {
    domains = [
      "test.example.com",
    ]
  }
}

resource "google_certificate_manager_certificate_map" "certificate_map" {
  name        = "certmgr-map"
  description = "My certificate map"
  project     = var.project_id
}

resource "google_certificate_manager_certificate_map_entry" "map_entry_web1" {
  project      = var.project_id
  name         = "certmgr-map-entry-web1"
  description  = "My test certificate map entry"
  map          = google_certificate_manager_certificate_map.certificate_map.name
  certificates = [google_certificate_manager_certificate.all.id]
  hostname     = "test.example.com"
}
