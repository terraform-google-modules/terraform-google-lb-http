# Global HTTP Load Balancer Terraform Module

Modular Global HTTP Load Balancer for GCE using forwarding rules.

This submodule allows for configuring dynamic backend outside Terraform.
As such, any changes to the `backends.groups` variable after creation will be ignored.

### Load Balancer Types
* [TCP load balancer](https://github.com/terraform-google-modules/terraform-google-lb)
* **HTTP/S load balancer**
* [Internal load balancer](https://github.com/terraform-google-modules/terraform-google-lb-internal)

## Compatibility

This module is meant for use with Terraform 0.12. If you haven't [upgraded](https://www.terraform.io/upgrade-guides/0-12.html) and
need a Terraform 0.11.x-compatible version of this module, the last released version intended for Terraform 0.11.x is
[1.0.10](https://registry.terraform.io/modules/GoogleCloudPlatform/lb-http/google/1.0.10).

## Usage

```HCL
module "gce-lb-http" {
  source            = "GoogleCloudPlatform/lb-http/google//modules/dynamic_backends"
  name              = "group-http-lb"
  target_tags       = [module.mig1.target_tags, module.mig2.target_tags]
  backends = {
    default = {
      description                     = null
      protocol                        = "HTTP"
      port                            = var.service_port
      port_name                       = var.service_port_name
      timeout_sec                     = 10
      connection_draining_timeout_sec = null
      enable_cdn                      = false

      health_check = {
        check_interval_sec  = null
        timeout_sec         = null
        healthy_threshold   = null
        unhealthy_threshold = null
        request_path        = "/"
        port                = var.service_port
        host                = null
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
    }
  }
}
```

## Resources created

**Figure 1.** *diagram of terraform resources*

![architecture diagram](./diagram.png)

## Version

Current version is 3.0. Upgrade guides:
- [1.X -> 2.X](https://www.terraform.io/upgrade-guides/0-12.html)
- [2.X -> 3.0](./docs/upgrading-v2.0.0-v3.0.0.md)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| address | IP address self link | string | `"null"` | no |
| backends | Map backend indices to list of backend maps. | object | n/a | yes |
| cdn | Set to `true` to enable cdn on backend. | bool | `"false"` | no |
| certificate | Content of the SSL certificate. Required if `ssl` is `true` and `ssl_certificates` is empty. | string | `"null"` | no |
| create\_address | Create a new global address | bool | `"true"` | no |
| create\_url\_map | Set to `false` if url_map variable is provided. | bool | `"true"` | no |
| firewall\_networks | Names of the networks to create firewall rules in | list(string) | `<list>` | no |
| firewall\_projects | Names of the projects to create firewall rules in | list(string) | `<list>` | no |
| http\_forward | Set to `false` to disable HTTP port 80 forward | bool | `"true"` | no |
| ip\_version | IP version for the Global address (IPv4 or v6) - Empty defaults to IPV4 | string | `"null"` | no |
| name | Name for the forwarding rule and prefix for supporting resources | string | n/a | yes |
| private\_key | Content of the private SSL key. Required if `ssl` is `true` and `ssl_certificates` is empty. | string | `"null"` | no |
| project | The project to deploy to, if not set the default provider project is used. | string | n/a | yes |
| quic | Set to `true` to enable QUIC support | bool | `"false"` | no |
| security\_policy | The resource URL for the security policy to associate with the backend service | string | `"null"` | no |
| ssl | Set to `true` to enable SSL support, requires variable `ssl_certificates` - a list of self_link certs | bool | `"false"` | no |
| ssl\_certificates | SSL cert self_link list. Required if `ssl` is `true` and no `private_key` and `certificate` is provided. | list(string) | `<list>` | no |
| ssl\_policy | Selfink to SSL Policy | string | `"null"` | no |
| target\_tags | List of target tags for health check firewall rule. | list(string) | n/a | yes |
| url\_map | The url_map resource to use. Default is to send all traffic to first backend. | string | `"null"` | no |
| use\_ssl\_certificates | If true, use the certificates provided by `ssl_certificates`, otherwise, create cert from `private_key` and `certificate` | bool | `"false"` | no |

## Outputs

| Name | Description |
|------|-------------|
| backend\_services | The backend service resources. |
| external\_ip | The external IP assigned to the global fowarding rule. |
| http\_proxy | The HTTP proxy used by this module. |
| https\_proxy | The HTTPS proxyused by this module. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

- [`google_compute_global_forwarding_rule.http`](https://www.terraform.io/docs/providers/google/r/compute_global_forwarding_rule.html): The global HTTP forwarding rule.
- [`google_compute_global_forwarding_rule.https`](https://www.terraform.io/docs/providers/google/r/compute_global_forwarding_rule.html): The global HTTPS forwarding rule created when `ssl` is `true`.
- [`google_compute_target_http_proxy.default`](https://www.terraform.io/docs/providers/google/r/compute_target_http_proxy.html): The HTTP proxy resource that binds the url map. Created when input `ssl` is `false`.
- [`google_compute_target_https_proxy.default`](https://www.terraform.io/docs/providers/google/r/compute_target_https_proxy.html): The HTTPS proxy resource that binds the url map. Created when input `ssl` is `true`.
- [`google_compute_ssl_certificate.default`](https://www.terraform.io/docs/providers/google/r/compute_ssl_certificate.html): The certificate resource created when input `ssl` is `true`.
- [`google_compute_url_map.default`](https://www.terraform.io/docs/providers/google/r/compute_url_map.html): The default URL map resource when input `url_map` is not provided.
- [`google_compute_backend_service.default.*`](https://www.terraform.io/docs/providers/google/r/compute_backend_service.html): The backend services created for each of the `backend_params` elements.
- [`google_compute_health_check.default.*`](https://www.terraform.io/docs/providers/google/r/compute_health_check.html): Health check resources create for each of the backend services.
- [`google_compute_firewall.default-hc`](https://www.terraform.io/docs/providers/google/r/compute_firewall.html): Firewall rule created for each of the backed services to alllow health checks to the instance group.
