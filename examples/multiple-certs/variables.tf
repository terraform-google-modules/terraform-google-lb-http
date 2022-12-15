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

variable "group1_region" {
  default = "us-west1"
}

variable "group2_region" {
  default = "us-central1"
}

variable "group3_region" {
  default = "us-east1"
}

variable "network_name" {
  default = "tf-lb-https-multi-cert"
}

variable "project" {
  type = string
}
