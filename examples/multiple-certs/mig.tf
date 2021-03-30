/**
 * Copyright 2017 Google LLC
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

data "template_file" "group1-startup-script" {
  template = file(format("%s/gceme.sh.tpl", path.module))

  vars = {
    PROXY_PATH = "/group1"
  }
}

data "template_file" "group2-startup-script" {
  template = file(format("%s/gceme.sh.tpl", path.module))

  vars = {
    PROXY_PATH = "/group2"
  }
}

data "template_file" "group3-startup-script" {
  template = file(format("%s/gceme.sh.tpl", path.module))

  vars = {
    PROXY_PATH = "/group3"
  }
}

module "mig1_template" {
  source     = "terraform-google-modules/vm/google//modules/instance_template"
  version    = "6.2.0"
  network    = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.group1.self_link
  service_account = {
    email  = ""
    scopes = ["cloud-platform"]
  }
  name_prefix          = "${var.network_name}-group1"
  startup_script       = data.template_file.group1-startup-script.rendered
  source_image_family  = "ubuntu-1804-lts"
  source_image_project = "ubuntu-os-cloud"
  tags = [
    "${var.network_name}-group1",
    module.cloud-nat-group1.router_name
  ]
}

module "mig1" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "6.2.0"
  instance_template = module.mig1_template.self_link
  region            = var.group1_region
  hostname          = "${var.network_name}-group1"
  target_size       = 2
  named_ports = [{
    name = "http",
    port = 80
  }]
  network    = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.group1.self_link
}

module "mig2_template" {
  source     = "terraform-google-modules/vm/google//modules/instance_template"
  version    = "6.2.0"
  network    = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.group2.self_link
  service_account = {
    email  = ""
    scopes = ["cloud-platform"]
  }
  name_prefix    = "${var.network_name}-group2"
  startup_script = data.template_file.group2-startup-script.rendered
  tags = [
    "${var.network_name}-group2",
    module.cloud-nat-group2.router_name
  ]
}

module "mig2" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "6.2.0"
  instance_template = module.mig2_template.self_link
  region            = var.group2_region
  hostname          = "${var.network_name}-group2"
  target_size       = 2
  named_ports = [{
    name = "http",
    port = 80
  }]
  network    = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.group2.self_link
}


module "mig3_template" {
  source     = "terraform-google-modules/vm/google//modules/instance_template"
  version    = "6.2.0"
  network    = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.group3.self_link
  service_account = {
    email  = ""
    scopes = ["cloud-platform"]
  }
  name_prefix    = "${var.network_name}-group3"
  startup_script = data.template_file.group3-startup-script.rendered
  tags = [
    "${var.network_name}-group3",
    module.cloud-nat-group2.router_name
  ]
}

module "mig3" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "6.2.0"
  instance_template = module.mig3_template.self_link
  region            = var.group3_region
  hostname          = "${var.network_name}-group3"
  target_size       = 2
  named_ports = [{
    name = "http",
    port = 80
  }]
  network    = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.group3.self_link
}

