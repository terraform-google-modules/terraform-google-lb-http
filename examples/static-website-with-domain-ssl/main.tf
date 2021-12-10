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
  project = var.project
}

provider "google-beta" {
  project = var.project
}

locals {
  storage_buckets = tolist(module.website-storage-buckets.names_list)
  backend_buckets = { for bucket in local.storage_buckets : index(local.storage_buckets, bucket) => {
    "bucket_name" = "${bucket}"
    "description" = null
    "cdn_policy" = {
      "cache_mode"                   = "CACHE_ALL_STATIC"
      "client_ttl"                   = 3600
      "default_ttl"                  = 3600
      "max_ttl"                      = 86400
      "negative_caching"             = false
      "signed_url_cache_max_age_sec" = 7200
    }
    }
  }
}

module "website-dns-zone" {
  source     = "terraform-google-modules/cloud-dns/google"
  project_id = var.project
  type       = "public"
  name       = "website-zone"
  domain     = "${var.domain}."
  recordsets = [
    {
      name = ""
      type = "A"
      ttl  = 300
      records = [
        "${module.load-balancer.external_ip}"
      ]
    },
    {
      name = "www"
      type = "CNAME"
      ttl  = 300
      records = [
        "${var.domain}."
      ]
    }
  ]

  depends_on = [module.load-balancer]
}

module "website-storage-buckets" {
  source           = "terraform-google-modules/cloud-storage/google"
  prefix           = ""
  names            = ["website-bucket-"]
  randomize_suffix = true
  project_id       = var.project
  location         = "US"
  set_viewer_roles = true
  viewers          = ["allUsers"]
  website = {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  cors = [{
    origin          = ["http://${var.domain}"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }]
}

module "load-balancer" {
  source                          = "../../modules/backend_bucket"
  project                         = var.project
  name                            = "website-lb"
  ssl                             = true
  managed_ssl_certificate_domains = ["www.${var.domain}", "${var.domain}"]
  https_redirect                  = true
  buckets                         = local.backend_buckets
  cdn                             = true

  depends_on = [module.website-storage-buckets]

}

resource "google_storage_bucket_object" "index.html" {
  name         = "index.html"
  content      = file("index.html")
  content_type = "text/html;charset=utf-8"
  bucket       = module.website-storage-buckets[0].name
}

resource "google_storage_bucket_object" "404.html" {
  name         = "404.html"
  content      = file("404.html")
  content_type = "text/html;charset=utf-8"
  bucket       = module.website-storage-buckets[0].name
}
