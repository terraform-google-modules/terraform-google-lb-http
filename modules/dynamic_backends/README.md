# Global HTTP Load Balancer Terraform Module
Modular Global HTTP Load Balancer for GCE using forwarding rules.

This submodule allows for configuring dynamic backend outside Terraform.
As such, any changes to the `backends.groups` variable after creation will be ignored.


## Load Balancer Types

- [TCP load balancer](https://github.com/terraform-google-modules/terraform-google-lb)
- **HTTP/S load balancer**
- [Internal load balancer](https://github.com/terraform-google-modules/terraform-google-lb-internal)

## Compatibility

This module is meant for use with Terraform 1.3+ and tested using Terraform 1.3. If you find incompatibilities using Terraform >=1.3, please open an issue. If you haven't
[upgraded](https://www.terraform.io/upgrade-guides/0-13.html) and need a Terraform
0.12.x-compatible version of this module, the last released version
intended for Terraform 0.12.x is [v4.5.0](https://registry.terraform.io/modules/GoogleCloudPlatform/lb-http/google/4.5.0).

## Version

Current version is 9.0. Upgrade guides:

- [2.X -> 3.0](/docs/upgrading-v2.0.0-v3.0.0.md)
- [3.X -> 4.0](/docs/upgrading_to_v4.0.md)
- [6.X -> 7.0](/docs/upgrading_to_v7.0.md)
- [7.X -> 8.0](/docs/upgrading_to_v8.0.md)
- [8.X -> 9.0](/docs/upgrading_to_v9.0.md)
- [9.X -> 10.0](/docs/upgrading_to_v10.0.md)

## Usage

```HCL
module "gce-lb-http" {
  source            = "GoogleCloudPlatform/lb-http/google//modules/dynamic_backends"
  version           = "~> 9.0"

  project           = "my-project-id"
  name              = "group-http-lb"
  target_tags       = [module.mig1.target_tags, module.mig2.target_tags]
  backends = {
    default = {
      port                            = var.service_port
      protocol                        = "HTTP"
      port_name                       = var.service_port_name
      timeout_sec                     = 10
      enable_cdn                      = false


      health_check = {
        request_path        = "/"
        port                = var.service_port
      }

      log_config = {
        enable = true
        sample_rate = 1.0
      }

      groups = [
        {
          # Each node pool instance group should be added to the backend.
          group                        = var.backend
        },
      ]

      iap_config = {
        enable               = false
      }
    }
  }
}
```


## Resources created

**Figure 1.** _diagram of terraform resources_

![architecture diagram](/diagram.png)


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| address | Existing IPv4 address to use (the actual IP address value) | `string` | `null` | no |
| backends | Map backend indices to list of backend maps. | <pre>map(object({<br>    port                    = optional(number)<br>    project                 = optional(string)<br>    protocol                = optional(string)<br>    port_name               = optional(string)<br>    description             = optional(string)<br>    enable_cdn              = optional(bool)<br>    compression_mode        = optional(string)<br>    security_policy         = optional(string, null)<br>    edge_security_policy    = optional(string, null)<br>    custom_request_headers  = optional(list(string))<br>    custom_response_headers = optional(list(string))<br><br>    timeout_sec                     = optional(number)<br>    connection_draining_timeout_sec = optional(number)<br>    session_affinity                = optional(string)<br>    affinity_cookie_ttl_sec         = optional(number)<br>    locality_lb_policy              = optional(string)<br><br>    health_check = optional(object({<br>      host                = optional(string)<br>      request_path        = optional(string)<br>      request             = optional(string)<br>      response            = optional(string)<br>      port                = optional(number)<br>      port_name           = optional(string)<br>      proxy_header        = optional(string)<br>      port_specification  = optional(string)<br>      protocol            = optional(string)<br>      check_interval_sec  = optional(number)<br>      timeout_sec         = optional(number)<br>      healthy_threshold   = optional(number)<br>      unhealthy_threshold = optional(number)<br>      logging             = optional(bool)<br>    }))<br><br>    log_config = object({<br>      enable      = optional(bool)<br>      sample_rate = optional(number)<br>    })<br><br>    groups = list(object({<br>      group       = string<br>      description = optional(string)<br><br>      balancing_mode               = optional(string)<br>      capacity_scaler              = optional(number)<br>      max_connections              = optional(number)<br>      max_connections_per_instance = optional(number)<br>      max_connections_per_endpoint = optional(number)<br>      max_rate                     = optional(number)<br>      max_rate_per_instance        = optional(number)<br>      max_rate_per_endpoint        = optional(number)<br>      max_utilization              = optional(number)<br>    }))<br>    iap_config = optional(object({<br>      enable               = bool<br>      oauth2_client_id     = optional(string)<br>      oauth2_client_secret = optional(string)<br>    }))<br>    cdn_policy = optional(object({<br>      cache_mode                   = optional(string)<br>      signed_url_cache_max_age_sec = optional(string)<br>      default_ttl                  = optional(number)<br>      max_ttl                      = optional(number)<br>      client_ttl                   = optional(number)<br>      negative_caching             = optional(bool)<br>      negative_caching_policy = optional(object({<br>        code = optional(number)<br>        ttl  = optional(number)<br>      }))<br>      serve_while_stale = optional(number)<br>      cache_key_policy = optional(object({<br>        include_host           = optional(bool)<br>        include_protocol       = optional(bool)<br>        include_query_string   = optional(bool)<br>        query_string_blacklist = optional(list(string))<br>        query_string_whitelist = optional(list(string))<br>        include_http_headers   = optional(list(string))<br>        include_named_cookies  = optional(list(string))<br>      }))<br>      bypass_cache_on_request_headers = optional(list(string))<br>    }))<br>    outlier_detection = optional(object({<br>      base_ejection_time = optional(object({<br>        seconds = number<br>        nanos   = optional(number)<br>      }))<br>      consecutive_errors                    = optional(number)<br>      consecutive_gateway_failure           = optional(number)<br>      enforcing_consecutive_errors          = optional(number)<br>      enforcing_consecutive_gateway_failure = optional(number)<br>      enforcing_success_rate                = optional(number)<br>      interval = optional(object({<br>        seconds = number<br>        nanos   = optional(number)<br>      }))<br>      max_ejection_percent        = optional(number)<br>      success_rate_minimum_hosts  = optional(number)<br>      success_rate_request_volume = optional(number)<br>      success_rate_stdev_factor   = optional(number)<br>    }))<br>  }))</pre> | n/a | yes |
| certificate | Content of the SSL certificate. Requires `ssl` to be set to `true` and `create_ssl_certificate` set to `true` | `string` | `null` | no |
| certificate\_map | Certificate Map ID in format projects/{project}/locations/global/certificateMaps/{name}. Identifies a certificate map associated with the given target proxy.  Requires `ssl` to be set to `true` | `string` | `null` | no |
| create\_address | Create a new global IPv4 address | `bool` | `true` | no |
| create\_ipv6\_address | Allocate a new IPv6 address. Conflicts with "ipv6\_address" - if both specified, "create\_ipv6\_address" takes precedence. | `bool` | `false` | no |
| create\_ssl\_certificate | If `true`, Create certificate using `private_key/certificate` | `bool` | `false` | no |
| create\_url\_map | Set to `false` if url\_map variable is provided. | `bool` | `true` | no |
| edge\_security\_policy | The resource URL for the edge security policy to associate with the backend service | `string` | `null` | no |
| enable\_ipv6 | Enable IPv6 address on the CDN load-balancer | `bool` | `false` | no |
| firewall\_networks | Names of the networks to create firewall rules in | `list(string)` | <pre>[<br>  "default"<br>]</pre> | no |
| firewall\_projects | Names of the projects to create firewall rules in | `list(string)` | <pre>[<br>  "default"<br>]</pre> | no |
| http\_forward | Set to `false` to disable HTTP port 80 forward | `bool` | `true` | no |
| http\_keep\_alive\_timeout\_sec | Specifies how long to keep a connection open, after completing a response, while there is no matching traffic (in seconds). | `number` | `null` | no |
| http\_port | The port for the HTTP load balancer | `number` | `80` | no |
| https\_port | The port for the HTTPS load balancer | `number` | `443` | no |
| https\_redirect | Set to `true` to enable https redirect on the lb. | `bool` | `false` | no |
| ipv6\_address | An existing IPv6 address to use (the actual IP address value) | `string` | `null` | no |
| labels | The labels to attach to resources created by this module | `map(string)` | `{}` | no |
| load\_balancing\_scheme | Load balancing scheme type (EXTERNAL for classic external load balancer, EXTERNAL\_MANAGED for Envoy-based load balancer, and INTERNAL\_SELF\_MANAGED for traffic director) | `string` | `"EXTERNAL"` | no |
| managed\_ssl\_certificate\_domains | Create Google-managed SSL certificates for specified domains. Requires `ssl` to be set to `true` | `list(string)` | `[]` | no |
| name | Name for the forwarding rule and prefix for supporting resources | `string` | n/a | yes |
| name\_prefixes | Map of resource name prefixes allowing name customization. `null` values fallback to module defaults. | <pre>object({<br>    address                    = optional(string, null)<br>    address_ipv6               = optional(string, null)<br>    certificate                = optional(string, null)<br>    http_forwarding_rule       = optional(string, null)<br>    http_ipv6_forwarding_rule  = optional(string, null)<br>    https_forwarding_rule      = optional(string, null)<br>    https_ipv6_forwarding_rule = optional(string, null)<br>    target_http_proxy          = optional(string, null)<br>    target_https_proxy         = optional(string, null)<br>    url_map                    = optional(string, null)<br>    url_map_https_redirect     = optional(string, null)<br>    backend_service            = optional(string, null)<br>    health_check               = optional(string, null)<br>  })</pre> | `{}` | no |
| name\_suffixes | Map of suffixes to the created resource names. | <pre>object({<br>    address                    = optional(string, "-address")<br>    address_ipv6               = optional(string, "-ipv6-address")<br>    certificate                = optional(string, "-cert")<br>    http_forwarding_rule       = optional(string, "")<br>    http_ipv6_forwarding_rule  = optional(string, "-ipv6-http")<br>    https_forwarding_rule      = optional(string, "-https")<br>    https_ipv6_forwarding_rule = optional(string, "-ipv6-https")<br>    target_http_proxy          = optional(string, "-http-proxy")<br>    target_https_proxy         = optional(string, "-https-proxy")<br>    url_map                    = optional(string, "-url-map")<br>    url_map_https_redirect     = optional(string, "-https-redirect")<br>    backend_service            = optional(string, "")<br>    health_check               = optional(string, "")<br>  })</pre> | `{}` | no |
| network | Network for INTERNAL\_SELF\_MANAGED load balancing scheme | `string` | `"default"` | no |
| private\_key | Content of the private SSL key. Requires `ssl` to be set to `true` and `create_ssl_certificate` set to `true` | `string` | `null` | no |
| project | The project to deploy to, if not set the default provider project is used. | `string` | n/a | yes |
| quic | Specifies the QUIC override policy for this resource. Set true to enable HTTP/3 and Google QUIC support, false to disable both. Defaults to null which enables support for HTTP/3 only. | `bool` | `null` | no |
| random\_certificate\_suffix | Bool to enable/disable random certificate name generation. Set and keep this to true if you need to change the SSL cert. | `bool` | `false` | no |
| security\_policy | The resource URL for the security policy to associate with the backend service | `string` | `null` | no |
| server\_tls\_policy | The resource URL for the server TLS policy to associate with the https proxy service | `string` | `null` | no |
| ssl | Set to `true` to enable SSL support. If `true` then at least one of these are required: 1) `ssl_certificates` OR 2) `create_ssl_certificate` set to `true` and `private_key/certificate` OR  3) `managed_ssl_certificate_domains`, OR 4) `certificate_map` | `bool` | `false` | no |
| ssl\_certificates | SSL cert self\_link list. Requires `ssl` to be set to `true` | `list(string)` | `[]` | no |
| ssl\_policy | Selfink to SSL Policy | `string` | `null` | no |
| target\_service\_accounts | List of target service accounts for health check firewall rule. Exactly one of target\_tags or target\_service\_accounts should be specified. | `list(string)` | `[]` | no |
| target\_tags | List of target tags for health check firewall rule. Exactly one of target\_tags or target\_service\_accounts should be specified. | `list(string)` | `[]` | no |
| url\_map | The url\_map resource to use. Default is to send all traffic to first backend. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| backend\_services | The backend service resources. |
| external\_ip | The external IPv4 assigned to the global fowarding rule. |
| external\_ipv6\_address | The external IPv6 assigned to the global fowarding rule. |
| http\_proxy | The HTTP proxy used by this module. |
| https\_proxy | The HTTPS proxy used by this module. |
| ipv6\_enabled | Whether IPv6 configuration is enabled on this load-balancer |
| ssl\_certificate\_created | The SSL certificate create from key/pem |
| url\_map | The default URL map used by this module. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

- [`google_compute_global_forwarding_rule.http`](https://www.terraform.io/docs/providers/google/r/compute_global_forwarding_rule.html): The global HTTP forwarding rule.
- [`google_compute_global_forwarding_rule.https`](https://www.terraform.io/docs/providers/google/r/compute_global_forwarding_rule.html): The global HTTPS forwarding rule created when `ssl` is `true`.
- [`google_compute_target_http_proxy.default`](https://www.terraform.io/docs/providers/google/r/compute_target_http_proxy.html): The HTTP proxy resource that binds the url map. Created when input `ssl` is `false`.
- [`google_compute_target_https_proxy.default`](https://www.terraform.io/docs/providers/google/r/compute_target_https_proxy.html): The HTTPS proxy resource that binds the url map. Created when input `ssl` is `true`.
- [`google_compute_ssl_certificate.default`](https://www.terraform.io/docs/providers/google/r/compute_ssl_certificate.html): The certificate resource created when input `ssl` is `true` and `managed_ssl_certificate_domains` not specified.
- [`google_compute_managed_ssl_certificate.default`](https://www.terraform.io/docs/providers/google/r/compute_managed_ssl_certificate.html): The Google-managed certificate resource created when input `ssl` is `true` and `managed_ssl_certificate_domains` is specified.
- [`google_compute_url_map.default`](https://www.terraform.io/docs/providers/google/r/compute_url_map.html): The default URL map resource when input `url_map` is not provided.
- [`google_compute_backend_service.default.*`](https://www.terraform.io/docs/providers/google/r/compute_backend_service.html): The backend services created for each of the `backend_params` elements.
- [`google_compute_health_check.default.*`](https://www.terraform.io/docs/providers/google/r/compute_health_check.html):
  Health check resources created for each of the (non global NEG) backend services.
- [`google_compute_firewall.default-hc`](https://www.terraform.io/docs/providers/google/r/compute_firewall.html): Firewall rule created for each of the backed services to allow health checks to the instance group.
