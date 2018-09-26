/*
 * Copyright 2018 Google Inc.
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

data "template_file" "group-startup-script" {
  template = "${file("${format("%s/gceme.sh.tpl", path.module)}")}"

  vars {
    PROXY_PATH = ""
  }
}

module "mig1" {
  source                = "GoogleCloudPlatform/managed-instance-group/google"
  version               = "1.1.14"
  region                = "${var.region}"
  network               = "${var.network}"
  subnetwork            = "${var.subnetwork}"
  project               = "${var.service_project}"
  subnetwork_project    = "${var.host_project}"
  service_account_email = "${var.service_account_email}"
  name                  = "shared-vpc-mig"
  size                  = "${var.group_size}"
  target_tags           = ["allow-shared-vpc-mig"]
  service_port          = 80
  service_port_name     = "http"
  startup_script        = "${data.template_file.group-startup-script.rendered}"
}
