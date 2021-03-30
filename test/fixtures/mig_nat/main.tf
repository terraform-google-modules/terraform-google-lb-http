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

resource "random_id" "random_net" {
  byte_length = 2
}

provider "google" {
  version = "~> 3.53"
}

module "example" {
  source = "../../../examples/mig-nat-http-lb"

  network_name = "ci-lb-http-mig-nat-${random_id.random_net.hex}"
  project      = var.project_id
}
