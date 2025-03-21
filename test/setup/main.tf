/**
 * Copyright 2019 Google LLC
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

module "project-ci-lb-http" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 17.0"

  name                        = "ci-int-lb-http"
  random_project_id           = true
  org_id                      = var.org_id
  folder_id                   = var.folder_id
  billing_account             = var.billing_account
  default_service_account     = "keep"
  disable_dependent_services  = false
  disable_services_on_destroy = false
  deletion_policy             = "DELETE"

  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "storage-api.googleapis.com",
    "serviceusage.googleapis.com",
    "compute.googleapis.com",
    "run.googleapis.com",
    "iam.googleapis.com",
    "certificatemanager.googleapis.com",
    "vpcaccess.googleapis.com",
  ]
}

module "project-ci-lb-http-1" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 17.0"

  name                        = "ci-int-lb-http-1"
  random_project_id           = true
  org_id                      = var.org_id
  folder_id                   = var.folder_id
  billing_account             = var.billing_account
  default_service_account     = "keep"
  disable_dependent_services  = false
  disable_services_on_destroy = false
  deletion_policy             = "DELETE"

  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "storage-api.googleapis.com",
    "serviceusage.googleapis.com",
    "compute.googleapis.com",
    "run.googleapis.com",
    "iam.googleapis.com",
    "certificatemanager.googleapis.com",
    "vpcaccess.googleapis.com",
  ]
}
