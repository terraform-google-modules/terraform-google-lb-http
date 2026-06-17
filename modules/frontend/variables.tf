/**
 * Copyright 2024 Google LLC
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
  description = "Name for the forwarding rule and prefix for supporting resources"
  type        = string
}

variable "project_id" {
  description = "The project to deploy to, if not set the default provider project is used."
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

variable "create_url_map" {
  description = "Set to `false` if url_map variable is provided."
  type        = bool
  default     = true
}

variable "url_map_input" {
  description = "List of host, path and backend service for creating url_map"
  type = list(object({
    host            = string
    path            = string
    backend_service = string
  }))
  default = []
}

variable "url_map_resource_uri" {
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

variable "certificate_manager_certificates" {
  description = "Certificate Manager certificate self-links to associate with the HTTPS proxy. Requires `ssl` to be set to `true`. Cannot be combined with `certificate_map`."
  type        = list(string)
  default     = []
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
  description = "Load balancing scheme type (EXTERNAL for classic external load balancer, EXTERNAL_MANAGED for Envoy-based load balancer, INTERNAL_MANAGED for internal load balancer and INTERNAL_SELF_MANAGED for traffic director)"
  type        = string
  default     = "EXTERNAL_MANAGED"
}

variable "network" {
  description = "VPC network for the forwarding rule. The VPC network should have exactly one GLOBAL_MANAGED_PROXY subnetwork for every region where the forwarding rule is to be configured. Please go to the subnets tab of your VPC network and check if a GLOBAL_MANAGED_PROXY subnet exists under the `Reserved proxy-only subnets for load balancing` section. If a GLOBAL_MANAGED_PROXY subnet doesn't exist, create one for each required region."
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

variable "internal_forwarding_rules_config" {
  description = "List of internal managed forwarding rules config. One of 'address' or 'subnetwork' is required for each. It is only applicable for internal load balancer"
  type = list(object({
    region     = string
    address    = optional(string)
    subnetwork = optional(string)
  }))
  default = []
}

variable "http_forwarding_rule_name" {
  description = "Override the HTTP forwarding rule name for EXTERNAL load balancers. Defaults to `<name>` when null."
  type        = string
  default     = null
}

variable "https_forwarding_rule_name" {
  description = "Override the HTTPS forwarding rule name for EXTERNAL load balancers. Defaults to `<name>-https` when null."
  type        = string
  default     = null
}

variable "target_http_proxy_name" {
  description = "Override the target HTTP proxy resource name. Defaults to `<name>-http-proxy` when null."
  type        = string
  default     = null
}

variable "target_https_proxy_name" {
  description = "Override the target HTTPS proxy resource name. Defaults to `<name>-https-proxy` when null."
  type        = string
  default     = null
}

variable "forwarding_rule_names" {
  description = "Map of region to forwarding rule name override for INTERNAL_MANAGED. Defaults to `<name>-internal-managed-https-<region>` for any region not present in the map."
  type        = map(string)
  default     = {}
}

variable "http_forwarding_rule_names" {
  description = "Map of region to HTTP forwarding rule name override for INTERNAL_MANAGED. Defaults to `<name>-internal-managed-http-<region>` for any region not present in the map."
  type        = map(string)
  default     = {}
}

variable "ip_version" {
  description = "IP version for EXTERNAL forwarding rules. Set to `IPV4` when importing a resource that was originally created with ip_version explicitly set (prevents forced replacement). Defaults to null (GCP default: IPV4)."
  type        = string
  default     = null
}

variable "url_map_name" {
  description = "Override the URL map resource name. Defaults to `<name>-url-map` when null."
  type        = string
  default     = null
}

variable "url_map_config" {
  description = "Direct URL map configuration with full host_rule/path_matcher/route_rules support. Supports cross-project default_service self-links. Mutually exclusive with url_map_input — when set, url_map_input is ignored. Backward compatible: default null preserves existing url_map_input behaviour."
  type = object({
    default_service = optional(string)
    default_url_redirect = optional(object({
      host_redirect          = optional(string)
      path_redirect          = optional(string)
      https_redirect         = optional(bool)
      redirect_response_code = optional(string)
      strip_query            = optional(bool)
    }))
    host_rules = optional(list(object({
      hosts        = list(string)
      path_matcher = string
    })), [])
    path_matchers = optional(list(object({
      name            = string
      default_service = optional(string)
      default_url_redirect = optional(object({
        host_redirect          = optional(string)
        path_redirect          = optional(string)
        https_redirect         = optional(bool)
        redirect_response_code = optional(string)
        strip_query            = optional(bool)
      }))
      path_rules = optional(list(object({
        paths   = list(string)
        service = optional(string)
        url_redirect = optional(object({
          host_redirect          = optional(string)
          path_redirect          = optional(string)
          https_redirect         = optional(bool)
          redirect_response_code = optional(string)
          strip_query            = optional(bool)
        }))
      })), [])
      route_rules = optional(list(object({
        priority = number
        match_rules = optional(list(object({
          prefix_match    = optional(string)
          full_path_match = optional(string)
          regex_match     = optional(string)
          header_matches = optional(list(object({
            header_name = string
            exact_match = optional(string)
          })), [])
        })), [])
        url_redirect = optional(object({
          host_redirect          = optional(string)
          path_redirect          = optional(string)
          https_redirect         = optional(bool)
          redirect_response_code = optional(string)
          strip_query            = optional(bool)
        }))
        route_action = optional(object({
          weighted_backend_services = optional(list(object({
            backend_service = string
            weight          = number
          })), [])
        }))
      })), [])
    })), [])
  })
  default = null
}
