# Global HTTP Load Balancer Terraform Module for Serverless NEGs

This submodule allows you to create Cloud HTTP(S) Load Balancer with
[Serverless Network Endpoint Groups (NEGs)](https://cloud.google.com/load-balancing/docs/negs/serverless-neg-concepts)
and place serverless services from Cloud Run, Cloud Functions and App Engine
behind a Cloud Load Balancer.


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


## Usage

```HCL
module "lb-http" {
  source            = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version           = "~> 9.0"

  project           = "my-project-id"
  name              = "my-lb"

  ssl                             = true
  managed_ssl_certificate_domains = ["your-domain.com"]
  https_redirect                  = true
  backends = {
    default = {
      description                     = null
      protocol                        = "HTTP"
      port_name                       = var.service_port_name
      enable_cdn                      = false
      custom_request_headers          = null
      custom_response_headers         = null
      security_policy                 = null
      compression_mode                = null


      log_config = {
        enable = true
        sample_rate = 1.0
      }

      groups = [
        {
          # Your serverless service should have a NEG created that's referenced here.
          group = google_compute_region_network_endpoint_group.default.id
        }
      ]

      iap_config = {
        enable               = false
        oauth2_client_id     = null
        oauth2_client_secret = null
      }
    }
  }
}
```



<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| address | Existing IPv4 address to use (the actual IP address value) | `string` | `null` | no |
| backends | Map backend indices to list of backend maps. | <pre>map(object({<br>    protocol                = optional(string)<br>    port_name               = optional(string)<br>    description             = optional(string)<br>    enable_cdn              = optional(bool)<br>    compression_mode        = optional(string)<br>    security_policy         = optional(string, null)<br>    edge_security_policy    = optional(string, null)<br>    custom_request_headers  = optional(list(string))<br>    custom_response_headers = optional(list(string))<br><br>    connection_draining_timeout_sec = optional(number)<br>    session_affinity                = optional(string)<br>    affinity_cookie_ttl_sec         = optional(number)<br><br><br>    log_config = object({<br>      enable      = optional(bool)<br>      sample_rate = optional(number)<br>    })<br><br>    groups = list(object({<br>      group = string<br><br>    }))<br>    iap_config = object({<br>      enable               = bool<br>      oauth2_client_id     = optional(string)<br>      oauth2_client_secret = optional(string)<br>    })<br>    cdn_policy = optional(object({<br>      cache_mode                   = optional(string)<br>      signed_url_cache_max_age_sec = optional(string)<br>      default_ttl                  = optional(number)<br>      max_ttl                      = optional(number)<br>      client_ttl                   = optional(number)<br>      negative_caching             = optional(bool)<br>      negative_caching_policy = optional(object({<br>        code = optional(number)<br>        ttl  = optional(number)<br>      }))<br>      serve_while_stale = optional(number)<br>      cache_key_policy = optional(object({<br>        include_host           = optional(bool)<br>        include_protocol       = optional(bool)<br>        include_query_string   = optional(bool)<br>        query_string_blacklist = optional(list(string))<br>        query_string_whitelist = optional(list(string))<br>        include_http_headers   = optional(list(string))<br>        include_named_cookies  = optional(list(string))<br>      }))<br>    }))<br>  }))</pre> | n/a | yes |
| certificate | Content of the SSL certificate. Required if `ssl` is `true` and `ssl_certificates` is empty. | `string` | `null` | no |
| certificate\_map | Certificate Map ID in format projects/{project}/locations/global/certificateMaps/{name}. Identifies a certificate map associated with the given target proxy | `string` | `null` | no |
| create\_address | Create a new global IPv4 address | `bool` | `true` | no |
| create\_ipv6\_address | Allocate a new IPv6 address. Conflicts with "ipv6\_address" - if both specified, "create\_ipv6\_address" takes precedence. | `bool` | `false` | no |
| create\_url\_map | Set to `false` if url\_map variable is provided. | `bool` | `true` | no |
| edge\_security\_policy | The resource URL for the edge security policy to associate with the backend service | `string` | `null` | no |
| enable\_ipv6 | Enable IPv6 address on the CDN load-balancer | `bool` | `false` | no |
| http\_forward | Set to `false` to disable HTTP port 80 forward | `bool` | `true` | no |
| https\_redirect | Set to `true` to enable https redirect on the lb. | `bool` | `false` | no |
| ipv6\_address | An existing IPv6 address to use (the actual IP address value) | `string` | `null` | no |
| labels | The labels to attach to resources created by this module | `map(string)` | `{}` | no |
| load\_balancing\_scheme | Load balancing scheme type (EXTERNAL for classic external load balancer, EXTERNAL\_MANAGED for Envoy-based load balancer, and INTERNAL\_SELF\_MANAGED for traffic director) | `string` | `"EXTERNAL"` | no |
| managed\_ssl\_certificate\_domains | Create Google-managed SSL certificates for specified domains. Requires `ssl` to be set to `true` and `use_ssl_certificates` set to `false`. | `list(string)` | `[]` | no |
| name | Name for the forwarding rule and prefix for supporting resources | `string` | n/a | yes |
| network | Network for INTERNAL\_SELF\_MANAGED load balancing scheme | `string` | `"default"` | no |
| private\_key | Content of the private SSL key. Required if `ssl` is `true` and `ssl_certificates` is empty. | `string` | `null` | no |
| project | The project to deploy to, if not set the default provider project is used. | `string` | n/a | yes |
| quic | Specifies the QUIC override policy for this resource. Set true to enable HTTP/3 and Google QUIC support, false to disable both. Defaults to null which enables support for HTTP/3 only. | `bool` | `null` | no |
| random\_certificate\_suffix | Bool to enable/disable random certificate name generation. Set and keep this to true if you need to change the SSL cert. | `bool` | `false` | no |
| security\_policy | The resource URL for the security policy to associate with the backend service | `string` | `null` | no |
| ssl | Set to `true` to enable SSL support, requires variable `ssl_certificates` - a list of self\_link certs | `bool` | `false` | no |
| ssl\_certificates | SSL cert self\_link list. Required if `ssl` is `true` and no `private_key` and `certificate` is provided. | `list(string)` | `[]` | no |
| ssl\_policy | Selfink to SSL Policy | `string` | `null` | no |
| url\_map | The url\_map resource to use. Default is to send all traffic to first backend. | `string` | `null` | no |
| use\_ssl\_certificates | If true, use the certificates provided by `ssl_certificates`, otherwise, create cert from `private_key` and `certificate` | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| backend\_services | The backend service resources. |
| external\_ip | The external IPv4 assigned to the global fowarding rule. |
| external\_ipv6\_address | The external IPv6 assigned to the global fowarding rule. |
| http\_proxy | The HTTP proxy used by this module. |
| https\_proxy | The HTTPS proxy used by this module. |
| ipv6\_enabled | Whether IPv6 configuration is enabled on this load-balancer |
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
