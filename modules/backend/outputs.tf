/**
 * Copyright 2024 Google LLC
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

output "backend_service_info" {
  description = "Host, path and backend service mapping"
  value = concat(!local.is_backend_bucket ? [
    for mapping in var.host_path_mappings : {
      host            = mapping.host
      path            = mapping.path
      backend_service = google_compute_backend_service.default[0].self_link
    }
    ] : [], local.is_backend_bucket ? [for mapping in var.host_path_mappings : {
      host            = mapping.host
      path            = mapping.path
      backend_service = google_compute_backend_bucket.default[0].self_link
    }
    ] : []
  )
}

output "apphub_service_uri" {
  value = concat(
    !local.is_backend_bucket ? [
      {
        service_uri = "//compute.googleapis.com/${google_compute_backend_service.default[0].id}"
        service_id  = substr("${google_compute_backend_service.default[0].name}-${md5("global-be-service-${var.project_id}")}", 0, 63)
        location    = "global"
      }
    ] : [],
  )
  description = "Service URI in CAIS style to be used by Apphub."
}
