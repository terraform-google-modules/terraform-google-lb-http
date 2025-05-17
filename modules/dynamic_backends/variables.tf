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

variable "project" {
  description = "The project to deploy to, if not set the default provider project is used."
  type        = string
}

variable "name" {
  description = "Name for the forwarding rule and prefix for supporting resources"
  type        = string
}

variable "create_address" {
  type        = bool
  description = "Create a new global IPv4 address"
  default     = true
}

variable "address" {
  type        = string
  description = "Existing IPv4 address to use (the actual IP address value)"
  default     = null
}

variable "enable_ipv6" {
  type        = bool
  description = "Enable IPv6 address on the CDN load-balancer"
  default     = false
}

variable "create_ipv6_address" {
  type        = bool
  description = "Allocate a new IPv6 address. Conflicts with \"ipv6_address\" - if both specified, \"create_ipv6_address\" takes precedence."
  default     = false
}

variable "ipv6_address" {
  type        = string
  description = "An existing IPv6 address to use (the actual IP address value)"
  default     = null
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

variable "backends" {
  description = "Map backend indices to list of backend maps."
  type = map(object({
    port                    = optional(number)
    project                 = optional(string)
    protocol                = optional(string)
    port_name               = optional(string)
    description             = optional(string)
    enable_cdn              = optional(bool)
    compression_mode        = optional(string)
    security_policy         = optional(string, null)
    edge_security_policy    = optional(string, null)
    custom_request_headers  = optional(list(string))
    custom_response_headers = optional(list(string))

    timeout_sec                     = optional(number)
    connection_draining_timeout_sec = optional(number)
    session_affinity                = optional(string)
    affinity_cookie_ttl_sec         = optional(number)
    locality_lb_policy              = optional(string)

    health_check = optional(object({
      host                = optional(string)
      request_path        = optional(string)
      request             = optional(string)
      response            = optional(string)
      port                = optional(number)
      port_name           = optional(string)
      proxy_header        = optional(string)
      port_specification  = optional(string)
      protocol            = optional(string)
      check_interval_sec  = optional(number)
      timeout_sec         = optional(number)
      healthy_threshold   = optional(number)
      unhealthy_threshold = optional(number)
      logging             = optional(bool)
    }))

    log_config = object({
      enable      = optional(bool)
      sample_rate = optional(number)
    })

    groups = list(object({
      group       = string
      description = optional(string)

      balancing_mode               = optional(string)
      capacity_scaler              = optional(number)
      max_connections              = optional(number)
      max_connections_per_instance = optional(number)
      max_connections_per_endpoint = optional(number)
      max_rate                     = optional(number)
      max_rate_per_instance        = optional(number)
      max_rate_per_endpoint        = optional(number)
      max_utilization              = optional(number)
    }))
    iap_config = optional(object({
      enable               = bool
      oauth2_client_id     = optional(string)
      oauth2_client_secret = optional(string)
    }))
    cdn_policy = optional(object({
      cache_mode                   = optional(string)
      signed_url_cache_max_age_sec = optional(string)
      default_ttl                  = optional(number)
      max_ttl                      = optional(number)
      client_ttl                   = optional(number)
      negative_caching             = optional(bool)
      negative_caching_policy = optional(object({
        code = optional(number)
        ttl  = optional(number)
      }))
      serve_while_stale = optional(number)
      cache_key_policy = optional(object({
        include_host           = optional(bool)
        include_protocol       = optional(bool)
        include_query_string   = optional(bool)
        query_string_blacklist = optional(list(string))
        query_string_whitelist = optional(list(string))
        include_http_headers   = optional(list(string))
        include_named_cookies  = optional(list(string))
      }))
      bypass_cache_on_request_headers = optional(list(string))
    }))
    outlier_detection = optional(object({
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
    }))
  }))
}

variable "create_url_map" {
  description = "Set to `false` if url_map variable is provided."
  type        = bool
  default     = true
}

variable "url_map" {
  description = "The url_map resource to use. Default is to send all traffic to first backend."
  type        = string
  default     = null
}

variable "http_forward" {
  description = "Set to `false` to disable HTTP port 80 forward"
  type        = bool
  default     = true
}

variable "ssl" {
  description = "Set to `true` to enable SSL support. If `true` then at least one of these are required: 1) `ssl_certificates` OR 2) `create_ssl_certificate` set to `true` and `private_key/certificate` OR  3) `managed_ssl_certificate_domains`, OR 4) `certificate_map`"
  type        = bool
  default     = false
}

variable "create_ssl_certificate" {
  description = "If `true`, Create certificate using `private_key/certificate`"
  type        = bool
  default     = false
}

variable "ssl_certificates" {
  description = "SSL cert self_link list. Requires `ssl` to be set to `true`"
  type        = list(string)
  default     = []
}

variable "private_key" {
  description = "Content of the private SSL key. Requires `ssl` to be set to `true` and `create_ssl_certificate` set to `true`"
  type        = string
  default     = null
}

variable "certificate" {
  description = "Content of the SSL certificate. Requires `ssl` to be set to `true` and `create_ssl_certificate` set to `true`"
  type        = string
  default     = null
}

variable "managed_ssl_certificate_domains" {
  description = "Create Google-managed SSL certificates for specified domains. Requires `ssl` to be set to `true`"
  type        = list(string)
  default     = []
}

variable "certificate_map" {
  description = "Certificate Map ID in format projects/{project}/locations/global/certificateMaps/{name}. Identifies a certificate map associated with the given target proxy.  Requires `ssl` to be set to `true`"
  type        = string
  default     = null
}

variable "ssl_policy" {
  type        = string
  description = "Selfink to SSL Policy"
  default     = null
}

variable "quic" {
  type        = bool
  description = "Specifies the QUIC override policy for this resource. Set true to enable HTTP/3 and Google QUIC support, false to disable both. Defaults to null which enables support for HTTP/3 only."
  default     = null
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

variable "https_redirect" {
  description = "Set to `true` to enable https redirect on the lb."
  type        = bool
  default     = false
}

variable "random_certificate_suffix" {
  description = "Bool to enable/disable random certificate name generation. Set and keep this to true if you need to change the SSL cert."
  type        = bool
  default     = false
}

variable "labels" {
  description = "The labels to attach to resources created by this module"
  type        = map(string)
  default     = {}
}

variable "load_balancing_scheme" {
  description = "Load balancing scheme type (EXTERNAL for classic external load balancer, EXTERNAL_MANAGED for Envoy-based load balancer, and INTERNAL_SELF_MANAGED for traffic director)"
  type        = string
  default     = "EXTERNAL"
}

variable "network" {
  description = "Network for INTERNAL_SELF_MANAGED load balancing scheme"
  type        = string
  default     = "default"
}

variable "server_tls_policy" {
  description = "The resource URL for the server TLS policy to associate with the https proxy service"
  type        = string
  default     = null
}

variable "http_port" {
  description = "The port for the HTTP load balancer"
  type        = number
  default     = 80
  validation {
    condition     = var.http_port >= 1 && var.http_port <= 65535
    error_message = "You must specify exactly one port between 1 and 65535"
  }
}

variable "https_port" {
  description = "The port for the HTTPS load balancer"
  type        = number
  default     = 443
  validation {
    condition     = var.https_port >= 1 && var.https_port <= 65535
    error_message = "You must specify exactly one port between 1 and 65535"
  }
}

variable "http_keep_alive_timeout_sec" {
  description = "Specifies how long to keep a connection open, after completing a response, while there is no matching traffic (in seconds)."
  type        = number
  default     = null
}

variable "name_suffixes" {
  description = "Map of suffixes to the created resource names."
  type = object({
    address                    = optional(string, "-address")
    address_ipv6               = optional(string, "-ipv6-address")
    certificate                = optional(string, "-cert")
    http_forwarding_rule       = optional(string, "")
    http_ipv6_forwarding_rule  = optional(string, "-ipv6-http")
    https_forwarding_rule      = optional(string, "-https")
    https_ipv6_forwarding_rule = optional(string, "-ipv6-https")
    target_http_proxy          = optional(string, "-http-proxy")
    target_https_proxy         = optional(string, "-https-proxy")
    url_map                    = optional(string, "-url-map")
    url_map_https_redirect     = optional(string, "-https-redirect")
    backend_service            = optional(string, "")
    health_check               = optional(string, "")
  })
  default = {}
}

variable "name_prefixes" {
  description = "Map of resource name prefixes allowing name customization. `null` values fallback to module defaults."
  type = object({
    address                    = optional(string, null)
    address_ipv6               = optional(string, null)
    certificate                = optional(string, null)
    http_forwarding_rule       = optional(string, null)
    http_ipv6_forwarding_rule  = optional(string, null)
    https_forwarding_rule      = optional(string, null)
    https_ipv6_forwarding_rule = optional(string, null)
    target_http_proxy          = optional(string, null)
    target_https_proxy         = optional(string, null)
    url_map                    = optional(string, null)
    url_map_https_redirect     = optional(string, null)
    backend_service            = optional(string, null)
    health_check               = optional(string, null)
  })
  default = {}
}
