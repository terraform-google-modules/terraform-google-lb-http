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
 
 provider "google" {
  project = var.project_id
}

provider "google-beta" {
  project = var.project_id
}

module "website-storage-bucket" {
  source                             = "terraform-google-modules/cloud-storage/google"
  prefix                             = ""
  names                              = ["website-bucket-"]
  randomize_suffix                   = true
  project_id                         = var.project
  versioning                         = {"${var.domain}" = true}
  force_destroy                      = {"${var.domain}" = true}
  location                           = "US"
  set_viewer_roles                   = true
  viewers                            = ["allUsers"]
  website                            = {
    main_page_suffix = "index.html"
    not_found_page = "404.html"
}
}

module "load-balancer-sslcert-CDN" {
  source                             = "../CFT/terraform-google-lb-http/modules/backend_bucket"
  project                            = var.project
  name                               = "website-lb"
  bucket_name                        = module.website-storage-bucket.name

  #instruction to create website storage bucket first
  depends_on                         = [module.website-storage-bucket]

}