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

variable region1 {
  default = "us-west1"
}

variable zone1 {
  default = "us-west1-b"
}

variable region2 {
  default = "us-central1"
}

variable zone2 {
  default = "us-central1-b"
}

variable region3 {
  default = "us-east1"
}

variable zone3 {
  default = "us-east1-b"
}

variable "vm_image" {
  default = "debian-cloud/debian-9"
}

provider google {
  region = "${var.region1}"
}

variable network_name {
  default = "multi-cert-example"
}

resource "google_compute_network" "default" {
  name                    = "${var.network_name}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "region1" {
  name          = "${var.network_name}"
  ip_cidr_range = "10.125.0.0/20"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.region1}"
}

resource "google_compute_subnetwork" "region2" {
  name          = "${var.network_name}"
  ip_cidr_range = "10.126.0.0/20"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.region2}"
}

resource "google_compute_subnetwork" "region3" {
  name          = "${var.network_name}"
  ip_cidr_range = "10.127.0.0/20"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.region3}"
}

module "gce-lb-https" {
  source               = "../../"
  name                 = "${var.network_name}-https-lb"
  target_tags          = ["${module.mig1.target_tags}", "${module.mig2.target_tags}", "${module.mig3.target_tags}"]
  firewall_networks    = ["${google_compute_network.default.name}"]
  ssl                  = true
  ssl_certificates     = ["${google_compute_ssl_certificate.example.*.self_link}"]
  use_ssl_certificates = true

  backends = {
    "0" = [
      {
        group = "${module.mig1.instance_group}"
      },
      {
        group = "${module.mig2.instance_group}"
      },
      {
        group = "${module.mig3.instance_group}"
      },
    ]
  }

  backend_params = [
    // health check path, port name, port number, timeout seconds.
    "/,http,80,10",
  ]
}
