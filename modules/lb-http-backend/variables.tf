/**
 * Copyright 2022 Google LLC
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


variable "name" {
  description = "Name for the backend service"
  type        = string
}

variable "load_balancing_scheme" {
  description = "Load balancing scheme type (EXTERNAL for classic external load balancer, EXTERNAL_MANAGED for Envoy-based load balancer, and INTERNAL_SELF_MANAGED for traffic director)"
  type        = string
  default     = "EXTERNAL_MANAGED"
}

variable "project_id" {
  description = "The project to deploy to, if not set the default provider project is used."
  type        = string
}

variable "protocol" {
  type    = string
  default = "HTTP"
}

variable "port_name" {
  type    = string
  default = "http"
}

variable "description" {
  type    = string
  default = null
}

variable "enable_cdn" {
  type    = bool
  default = false
}

variable "compression_mode" {
  type    = string
  default = "DISABLED"
}

variable "custom_request_headers" {
  type    = list(string)
  default = []
}

variable "custom_response_headers" {
  type    = list(string)
  default = []
}

variable "connection_draining_timeout_sec" {
  type    = number
  default = null
}

variable "session_affinity" {
  type    = string
  default = null
}

variable "affinity_cookie_ttl_sec" {
  type    = number
  default = null
}

variable "locality_lb_policy" {
  type    = string
  default = null
}

variable "log_config" {
  type = object({
    enable      = bool
    sample_rate = number
  })
  default = { enable = true, sample_rate = 1.0 }
}

variable "groups" {
  type = list(object({
    group       = string
    description = optional(string)
  }))
  default = []
}

variable "serverless_neg_backends" {
  type = list(object({
    region          = string
    type            = string // cloud-run, cloud-function, and app-engine
    service_name    = string
    service_version = optional(string)
  }))
  default = []
}

variable "iap_config" {
  type = object({
    enable               = bool
    oauth2_client_id     = optional(string)
    oauth2_client_secret = optional(string)
  })
  default = { enable = false }
}

variable "cdn_policy" {
  type = object({
    cache_mode                      = optional(string)
    signed_url_cache_max_age_sec    = optional(string)
    default_ttl                     = optional(number)
    max_ttl                         = optional(number)
    client_ttl                      = optional(number)
    negative_caching                = optional(bool)
    serve_while_stale               = optional(number)
    bypass_cache_on_request_headers = optional(list(string))
    negative_caching_policy = optional(object({
      code = optional(number)
      ttl  = optional(number)
    }))
    cache_key_policy = optional(object({
      include_host           = optional(bool)
      include_protocol       = optional(bool)
      include_query_string   = optional(bool)
      query_string_blacklist = optional(list(string))
      query_string_whitelist = optional(list(string))
      include_http_headers   = optional(list(string))
      include_named_cookies  = optional(list(string))
    }))
  })
  default = {}
}

variable "outlier_detection" {
  type = object({
    base_ejection_time = optional(object({
      seconds = number
      nanos   = optional(number)
    }))
    consecutive_errors                    = optional(number)
    consecutive_gateway_failure           = optional(number)
    enforcing_consecutive_errors          = optional(number)
    enforcing_consecutive_gateway_failure = optional(number)
    enforcing_success_rate                = optional(number)
    interval = optional(object({
      seconds = number
      nanos   = optional(number)
    }))
    max_ejection_percent        = optional(number)
    success_rate_minimum_hosts  = optional(number)
    success_rate_request_volume = optional(number)
    success_rate_stdev_factor   = optional(number)
  })
  default = null
}

variable "health_check" {
  type = object({
    host                = optional(string, null)
    request_path        = optional(string, null)
    request             = optional(string, null)
    response            = optional(string, null)
    port                = optional(number, null)
    port_name           = optional(string, null)
    proxy_header        = optional(string, null)
    port_specification  = optional(string, null)
    protocol            = optional(string, null)
    check_interval_sec  = optional(number, 5)
    timeout_sec         = optional(number, 5)
    healthy_threshold   = optional(number, 2)
    unhealthy_threshold = optional(number, 2)
    logging             = optional(bool, false)
  })
  default = null
}

variable "edge_security_policy" {
  description = "The resource URL for the edge security policy to associate with the backend service"
  type        = string
  default     = null
}

variable "security_policy" {
  description = "The resource URL for the security policy to associate with the backend service"
  type        = string
  default     = null
}

variable "host_path_mappings" {
  description = "The list of host/path for which traffic could be sent to the backend service"
  type        = list(object({ host : string, path : string }))
  default     = [{ host : "*", path : "/*" }]
}

variable "firewall_networks" {
  description = "Names of the networks to create firewall rules in"
  type        = list(string)
  default     = ["default"]
}

variable "firewall_projects" {
  description = "Names of the projects to create firewall rules in"
  type        = list(string)
  default     = ["default"]
}

variable "target_tags" {
  description = "List of target tags for health check firewall rule. Exactly one of target_tags or target_service_accounts should be specified."
  type        = list(string)
  default     = []
}

variable "target_service_accounts" {
  description = "List of target service accounts for health check firewall rule. Exactly one of target_tags or target_service_accounts should be specified."
  type        = list(string)
  default     = []
}