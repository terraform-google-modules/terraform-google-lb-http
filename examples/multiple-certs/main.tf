/*
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "group1_region" {
  default = "us-west1"
}

variable "group1_zone" {
  default = "us-west1-a"
}

variable "group2_region" {
  default = "us-central1"
}

variable "group2_zone" {
  default = "us-central1-f"
}

variable "group3_region" {
  default = "us-east1"
}

variable "group3_zone" {
  default = "us-east1-b"
}

variable "network_name" {
  default = "tf-lb-https-multi-cert"
}

variable "service_account" {
  type    = object({
    email  = string,
    scopes = list(string)
  })
  default = {
    email  = ""
    scopes = [
      "cloud-platform"]
  }
}

variable "project" {
  type = string
}

provider "google" {
  project = var.project
  version = "~> 2.7.0"
}

provider "google-beta" {
  project = var.project
  version = "~> 2.7.0"
}

resource "google_compute_network" "default" {
  name                    = var.network_name
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "group1" {
  name                     = var.network_name
  ip_cidr_range            = "10.125.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.group1_region
  private_ip_google_access = true
}

# Router and Cloud NAT are required for installing packages from repos (apache, php etc)
resource "google_compute_router" "group1" {
  name    = "${var.network_name}-gw-group1"
  network = google_compute_network.default.self_link
  region  = var.group1_region
}

module "cloud-nat-group1" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "1.0.0"
  router     = google_compute_router.group1.name
  project_id = var.project
  region     = var.group1_region
  name       = "${var.network_name}-cloud-nat-group1"
}

resource "google_compute_subnetwork" "group2" {
  name                     = var.network_name
  ip_cidr_range            = "10.126.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.group2_region
  private_ip_google_access = true
}

# Router and Cloud NAT are required for installing packages from repos (apache, php etc)
resource "google_compute_router" "group2" {
  name    = "${var.network_name}-gw-group2"
  network = google_compute_network.default.self_link
  region  = var.group2_region
}

module "cloud-nat-group2" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "1.0.0"
  router     = google_compute_router.group2.name
  project_id = var.project
  region     = var.group2_region
  name       = "${var.network_name}-cloud-nat-group2"
}

resource "google_compute_subnetwork" "group3" {
  name                     = var.network_name
  ip_cidr_range            = "10.127.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.group3_region
  private_ip_google_access = true
}

# Router and Cloud NAT are required for installing packages from repos (apache, php etc)
resource "google_compute_router" "group3" {
  name    = "${var.network_name}-gw-group3"
  network = google_compute_network.default.self_link
  region  = var.group3_region
}

module "cloud-nat-group3" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "1.0.0"
  router     = google_compute_router.group3.name
  project_id = var.project
  region     = var.group3_region
  name       = "${var.network_name}-cloud-nat-group3"
}

resource "random_id" "assets-bucket" {
  prefix      = "terraform-static-content-"
  byte_length = 2
}

module "gce-lb-https" {
  source               = "../../"
  name                 = var.network_name
  project              = var.project
  target_tags          = [
    "${var.network_name}-group1",
    module.cloud-nat-group1.router_name,
    "${var.network_name}-group2",
    module.cloud-nat-group2.router_name,
    "${var.network_name}-group3",
    module.cloud-nat-group3.router_name]
  firewall_networks    = [
    google_compute_network.default.self_link]
  url_map              = google_compute_url_map.https-multi-cert.self_link
  create_url_map       = false
  ssl                  = true
  ssl_certificates     = google_compute_ssl_certificate.example.*.self_link
  use_ssl_certificates = true

  backends = {
    "0" = [
      {
        group = module.mig1.instance_group
      },
      {
        group = module.mig2.instance_group
      },
      {
        group = module.mig3.instance_group
      },
    ]

    "1" = [
      {
        group = module.mig1.instance_group
      },
    ]

    "2" = [
      {
        group = module.mig2.instance_group
      },
    ]

    "3" = [
      {
        group = module.mig3.instance_group
      },
    ]
  }

  backend_params = [
    // health check path, port name, port number, timeout seconds.
    "/,http,80,10",
    "/,http,80,10",
    "/,http,80,10",
    "/,http,80,10",
  ]
}

resource "google_compute_url_map" "https-multi-cert" {
  // note that this is the name of the load balancer
  name            = var.network_name
  default_service = module.gce-lb-https.backend_services[0]

  host_rule {
    hosts        = [
      "*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = module.gce-lb-https.backend_services[0]

    path_rule {
      paths   = [
        "/group1",
        "/group1/*"]
      service = module.gce-lb-https.backend_services[1]
    }

    path_rule {
      paths   = [
        "/group2",
        "/group2/*"]
      service = module.gce-lb-https.backend_services[2]
    }

    path_rule {
      paths   = [
        "/group3",
        "/group3/*"]
      service = module.gce-lb-https.backend_services[3]
    }

    path_rule {
      paths   = [
        "/assets",
        "/assets/*"]
      service = google_compute_backend_bucket.assets.self_link
    }
  }
}

resource "google_compute_backend_bucket" "assets" {
  name        = random_id.assets-bucket.hex
  description = "Contains static resources for example app"
  bucket_name = google_storage_bucket.assets.name
  enable_cdn  = true
}

resource "google_storage_bucket" "assets" {
  name     = random_id.assets-bucket.hex
  location = "US"

  // delete bucket and contents on destroy.
  force_destroy = true
}

// The image object in Cloud Storage.
// Note that the path in the bucket matches the paths in the url map path rule above.
resource "google_storage_bucket_object" "image" {
  name         = "assets/gcp-logo.svg"
  content      = file("gcp-logo.svg")
  content_type = "image/svg+xml"
  bucket       = google_storage_bucket.assets.name
}

// Make object public readable.
resource "google_storage_object_acl" "image-acl" {
  bucket         = google_storage_bucket.assets.name
  object         = google_storage_bucket_object.image.name
  predefined_acl = "publicRead"
}

output "group1_region" {
  value = var.group1_region
}

output "group2_region" {
  value = var.group2_region
}

output "group3_region" {
  value = var.group3_region
}

output "load-balancer-ip" {
  value = module.gce-lb-https.external_ip
}

output "asset-url" {
  value = "https://${module.gce-lb-https.external_ip}/assets/gcp-logo.svg"
}
