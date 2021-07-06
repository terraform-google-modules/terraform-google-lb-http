# Global HTTP Load Balancer Terraform Module
Modular Global HTTP Load Balancer for GCE using forwarding rules.


- If you would like to allow for backend groups to be managed outside Terraform,
  such as via GKE services, see the [dynamic
  backends](./modules/dynamic_backends) submodule.
- If you would like to use load balancing with serverless backends (Cloud Run,
  Cloud Functions or App Engine), see the
  [serverless_negs](./modules/serverless_negs) submodule and
  [cloudrun](./examples/cloudrun) example.


## Load Balancer Types

* [TCP load balancer](https://github.com/terraform-google-modules/terraform-google-lb)
* **HTTP/S load balancer**
* [Internal load balancer](https://github.com/terraform-google-modules/terraform-google-lb-internal)

## Compatibility

This module is meant for use with Terraform 0.13. If you haven't
[upgraded](https://www.terraform.io/upgrade-guides/0-13.html) and need a Terraform
0.12.x-compatible version of this module, the last released version
intended for Terraform 0.12.x is [v4.5.0](https://registry.terraform.io/modules/GoogleCloudPlatform/lb-http/google/4.5.0).

## Usage

```HCL
module "gce-lb-http" {
  source            = "GoogleCloudPlatform/lb-http/google"
  version           = "~> 4.4"

  project           = "my-project-id"
  name              = "group-http-lb"
  target_tags       = [module.mig1.target_tags, module.mig2.target_tags]
  backends = {
    default = {
      description                     = null
      protocol                        = "HTTP"
      port                            = var.service_port
      port_name                       = var.service_port_name
      timeout_sec                     = 10
      enable_cdn                      = false
      custom_request_headers          = null
      custom_response_headers         = null
      security_policy                 = null

      connection_draining_timeout_sec = null
      session_affinity                = null
      affinity_cookie_ttl_sec         = null

      health_check = {
        check_interval_sec  = null
        timeout_sec         = null
        healthy_threshold   = null
        unhealthy_threshold = null
        request_path        = "/"
        port                = var.service_port
        host                = null
        logging             = null
      }

      log_config = {
        enable = true
        sample_rate = 1.0
      }

      groups = [
        {
          # Each node pool instance group should be added to the backend.
          group                        = var.backend
          balancing_mode               = null
          capacity_scaler              = null
          description                  = null
          max_connections              = null
          max_connections_per_instance = null
          max_connections_per_endpoint = null
          max_rate                     = null
          max_rate_per_instance        = null
          max_rate_per_endpoint        = null
          max_utilization              = null
        },
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

## Resources created

**Figure 1.** *diagram of terraform resources*

![architecture diagram](./diagram.png)

## Version

Current version is 3.0. Upgrade guides:

* [1.X -> 2.X](https://www.terraform.io/upgrade-guides/0-12.html)
* [2.X -> 3.0](./docs/upgrading-v2.0.0-v3.0.0.md)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| address | Existing IPv4 address to use (the actual IP address value) | `string` | `null` | no |
| backends | Map backend indices to list of backend maps. | <pre>map(object({<br>    protocol  = string<br>    port      = number<br>    port_name = string<br><br>    description             = string<br>    enable_cdn              = bool<br>    security_policy         = string<br>    custom_request_headers  = list(string)<br>    custom_response_headers = list(string)<br><br>    timeout_sec                     = number<br>    connection_draining_timeout_sec = number<br>    session_affinity                = string<br>    affinity_cookie_ttl_sec         = number<br><br>    health_check = object({<br>      check_interval_sec  = number<br>      timeout_sec         = number<br>      healthy_threshold   = number<br>      unhealthy_threshold = number<br>      request_path        = string<br>      port                = number<br>      host                = string<br>      logging             = bool<br>    })<br><br>    log_config = object({<br>      enable      = bool<br>      sample_rate = number<br>    })<br><br>    groups = list(object({<br>      group = string<br><br>      balancing_mode               = string<br>      capacity_scaler              = number<br>      description                  = string<br>      max_connections              = number<br>      max_connections_per_instance = number<br>      max_connections_per_endpoint = number<br>      max_rate                     = number<br>      max_rate_per_instance        = number<br>      max_rate_per_endpoint        = number<br>      max_utilization              = number<br>    }))<br>    iap_config = object({<br>      enable               = bool<br>      oauth2_client_id     = string<br>      oauth2_client_secret = string<br>    })<br>  }))</pre> | n/a | yes |
| cdn | Set to `true` to enable cdn on backend. | `bool` | `false` | no |
| certificate | Content of the SSL certificate. Required if `ssl` is `true` and `ssl_certificates` is empty. | `string` | `null` | no |
| create\_address | Create a new global IPv4 address | `bool` | `true` | no |
| create\_ipv6\_address | Allocate a new IPv6 address. Conflicts with "ipv6\_address" - if both specified, "create\_ipv6\_address" takes precedence. | `bool` | `false` | no |
| create\_url\_map | Set to `false` if url\_map variable is provided. | `bool` | `true` | no |
| enable\_ipv6 | Enable IPv6 address on the CDN load-balancer | `bool` | `false` | no |
| firewall\_networks | Names of the networks to create firewall rules in | `list(string)` | <pre>[<br>  "default"<br>]</pre> | no |
| firewall\_projects | Names of the projects to create firewall rules in | `list(string)` | <pre>[<br>  "default"<br>]</pre> | no |
| http\_forward | Set to `false` to disable HTTP port 80 forward | `bool` | `true` | no |
| https\_redirect | Set to `true` to enable https redirect on the lb. | `bool` | `false` | no |
| ipv6\_address | An existing IPv6 address to use (the actual IP address value) | `string` | `null` | no |
| managed\_ssl\_certificate\_domains | Create Google-managed SSL certificates for specified domains. Requires `ssl` to be set to `true` and `use_ssl_certificates` set to `false`. | `list(string)` | `[]` | no |
| name | Name for the forwarding rule and prefix for supporting resources | `string` | n/a | yes |
| private\_key | Content of the private SSL key. Required if `ssl` is `true` and `ssl_certificates` is empty. | `string` | `null` | no |
| project | The project to deploy to, if not set the default provider project is used. | `string` | n/a | yes |
| quic | Set to `true` to enable QUIC support | `bool` | `false` | no |
| random\_certificate\_suffix | Bool to enable/disable random certificate name generation. Set and keep this to true if you need to change the SSL cert. | `bool` | `false` | no |
| security\_policy | The resource URL for the security policy to associate with the backend service | `string` | `null` | no |
| ssl | Set to `true` to enable SSL support, requires variable `ssl_certificates` - a list of self\_link certs | `bool` | `false` | no |
| ssl\_certificates | SSL cert self\_link list. Required if `ssl` is `true` and no `private_key` and `certificate` is provided. | `list(string)` | `[]` | no |
| ssl\_policy | Selfink to SSL Policy | `string` | `null` | no |
| target\_service\_accounts | List of target service accounts for health check firewall rule. Exactly one of target\_tags or target\_service\_accounts should be specified. | `list(string)` | `[]` | no |
| target\_tags | List of target tags for health check firewall rule. Exactly one of target\_tags or target\_service\_accounts should be specified. | `list(string)` | `[]` | no |
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

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

* [`google_compute_global_forwarding_rule.http`](https://www.terraform.io/docs/providers/google/r/compute_global_forwarding_rule.html): The global HTTP forwarding rule.
* [`google_compute_global_forwarding_rule.https`](https://www.terraform.io/docs/providers/google/r/compute_global_forwarding_rule.html): The global HTTPS forwarding rule created when `ssl` is `true`.
* [`google_compute_target_http_proxy.default`](https://www.terraform.io/docs/providers/google/r/compute_target_http_proxy.html): The HTTP proxy resource that binds the url map. Created when input `ssl` is `false`.
* [`google_compute_target_https_proxy.default`](https://www.terraform.io/docs/providers/google/r/compute_target_https_proxy.html): The HTTPS proxy resource that binds the url map. Created when input `ssl` is `true`.
* [`google_compute_ssl_certificate.default`](https://www.terraform.io/docs/providers/google/r/compute_ssl_certificate.html): The certificate resource created when input `ssl` is `true` and `managed_ssl_certificate_domains` not specified.
* [`google_compute_managed_ssl_certificate.default`](https://www.terraform.io/docs/providers/google/r/compute_managed_ssl_certificate.html): The Google-managed certificate resource created when input `ssl` is `true` and `managed_ssl_certificate_domains` is specified.
* [`google_compute_url_map.default`](https://www.terraform.io/docs/providers/google/r/compute_url_map.html): The default URL map resource when input `url_map` is not provided.
* [`google_compute_backend_service.default.*`](https://www.terraform.io/docs/providers/google/r/compute_backend_service.html): The backend services created for each of the `backend_params` elements.
* [`google_compute_health_check.default.*`](https://www.terraform.io/docs/providers/google/r/compute_health_check.html):
  Health check resources created for each of the (non global NEG) backend services.
* [`google_compute_firewall.default-hc`](https://www.terraform.io/docs/providers/google/r/compute_firewall.html): Firewall rule created for each of the backed services to allow health checks to the instance group.
