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

variable project {
  description = "The project to deploy to, if not set the default provider project is used."
  default     = ""
}

variable region {
  description = "Region for cloud resources"
  default     = "us-central1"
}

variable firewall_networks {
  description = "Name of the networks to create firewall rules in"
  type        = "list"
  default     = ["default"]
}

variable name {
  description = "Name for the forwarding rule and prefix for supporting resources"
}

variable target_tags {
  description = "List of target tags for health check firewall rule."
  type        = "list"
}

variable backends {
  description = "Map backend indices to list of backend maps."
  type        = "map"
}

variable backend_params {
  description = "Comma-separated encoded list of parameters in order: health check path, service port name, service port, backend timeout seconds"
  type        = "list"
}

variable create_url_map {
  description = "Set to `false` if url_map variable is provided."
  default     = true
}

variable url_map {
  description = "The url_map resource to use. Default is to send all traffic to first backend."
  default     = ""
}

variable ssl {
  description = "Set to `true` to enable SSL support, requires variables `private_key` and `certificate`."
  default     = false
}

variable private_key {
  description = "Content of the private SSL key. Required if ssl is `true`."
  default     = ""
}

variable certificate {
  description = "Content of the SSL certificate. Required if ssl is `true`."
  default     = ""
}
