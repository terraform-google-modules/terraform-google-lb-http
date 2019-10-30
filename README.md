# Global HTTP Load Balancer Terraform Module

Modular Global HTTP Load Balancer for GCE using forwarding rules.

## Compatibility

This module is meant for use with Terraform 0.12. If you haven't [upgraded](https://www.terraform.io/upgrade-guides/0-12.html) and 
need a Terraform 0.11.x-compatible version of this module, the last released version intended for Terraform 0.11.x is
[1.0.10](https://registry.terraform.io/modules/GoogleCloudPlatform/lb-http/google/1.0.10).

## Usage

```HCL
module "gce-lb-http" {
  source            = "GoogleCloudPlatform/lb-http/google"
  name              = "group-http-lb"
  target_tags       = [module.mig1.target_tags, module.mig2.target_tags]
  backends          = {
    "0" = [
      {
        group = module.mig1.instance_group
        balancing_mode               = null
        capacity_scaler              = null
        description                  = null
        max_connections              = null
        max_connections_per_instance = null
        max_rate                     = null
        max_rate_per_instance        = null
        max_utilization              = null
      },
      {
        group = module.mig2.instance_group
        balancing_mode               = null
        capacity_scaler              = null
        description                  = null
        max_connections              = null
        max_connections_per_instance = null
        max_rate                     = null
        max_rate_per_instance        = null
        max_utilization              = null
      }
    ],
  }
  backend_params    = [
    # health check path, port name, port number, timeout seconds.
    "/,http,80,10"
  ]
}
```

## Resources created

**Figure 1.** *diagram of terraform resources*

![architecture diagram](./diagram.png)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| backend\_params | Comma-separated encoded list of parameters in order: health check path, service port name, service port, backend timeout seconds | list(string) | n/a | yes |
| backend\_protocol | The protocol with which to talk to the backend service | string | `"HTTP"` | no |
| backends | Map backend indices to list of backend maps. | object | n/a | yes |
| cdn | Set to `true` to enable cdn on backend. | bool | `"false"` | no |
| certificate | Content of the SSL certificate. Required if `ssl` is `true` and `ssl_certificates` is empty. | string | `""` | no |
| create\_url\_map | Set to `false` if url_map variable is provided. | bool | `"true"` | no |
| firewall\_networks | Names of the networks to create firewall rules in | list(string) | `<list>` | no |
| firewall\_projects | Names of the projects to create firewall rules in | list(string) | `<list>` | no |
| http\_forward | Set to `false` to disable HTTP port 80 forward | bool | `"true"` | no |
| ip\_version | IP version for the Global address (IPv4 or v6) - Empty defaults to IPV4 | string | `""` | no |
| name | Name for the forwarding rule and prefix for supporting resources | string | n/a | yes |
| private\_key | Content of the private SSL key. Required if `ssl` is `true` and `ssl_certificates` is empty. | string | `""` | no |
| project | The project to deploy to, if not set the default provider project is used. | string | n/a | yes |
| region | Region for cloud resources | string | `"us-central1"` | no |
| security\_policy | The resource URL for the security policy to associate with the backend service | string | `""` | no |
| ssl | Set to `true` to enable SSL support, requires variable `ssl_certificates` - a list of self_link certs | bool | `"false"` | no |
| ssl\_certificates | SSL cert self_link list. Required if `ssl` is `true` and no `private_key` and `certificate` is provided. | list(string) | `<list>` | no |
| target\_tags | List of target tags for health check firewall rule. | list(string) | n/a | yes |
| url\_map | The url_map resource to use. Default is to send all traffic to first backend. | string | `""` | no |
| use\_ssl\_certificates | If true, use the certificates provided by `ssl_certificates`, otherwise, create cert from `private_key` and `certificate` | bool | `"false"` | no |

## Outputs

| Name | Description |
|------|-------------|
| backend\_services | The backend service resources. |
| external\_ip | The external IP assigned to the global fowarding rule. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

- [`google_compute_global_forwarding_rule.http`](https://www.terraform.io/docs/providers/google/r/compute_global_forwarding_rule.html): The global HTTP forwarding rule.
- [`google_compute_global_forwarding_rule.https`](https://www.terraform.io/docs/providers/google/r/compute_global_forwarding_rule.html): The global HTTPS forwarding rule created when `ssl` is `true`.
- [`google_compute_target_http_proxy.default`](https://www.terraform.io/docs/providers/google/r/compute_target_http_proxy.html): The HTTP proxy resource that binds the url map. Created when input `ssl` is `false`.
- [`google_compute_target_https_proxy.default`](https://www.terraform.io/docs/providers/google/r/compute_target_https_proxy.html): The HTTPS proxy resource that binds the url map. Created when input `ssl` is `true`.
- [`google_compute_ssl_certificate.default`](https://www.terraform.io/docs/providers/google/r/compute_ssl_certificate.html): The certificate resource created when input `ssl` is `true`.
- [`google_compute_url_map.default`](https://www.terraform.io/docs/providers/google/r/compute_url_map.html): The default URL map resource when input `url_map` is not provided.
- [`google_compute_backend_service.default.*`](https://www.terraform.io/docs/providers/google/r/compute_backend_service.html): The backend services created for each of the `backend_params` elements.
- [`google_compute_http_health_check.default.*`](https://www.terraform.io/docs/providers/google/r/compute_http_health_check.html): Health check resources create for each of the backend services.
- [`google_compute_firewall.default-hc`](https://www.terraform.io/docs/providers/google/r/compute_firewall.html): Firewall rule created for each of the backed services to alllow health checks to the instance group.
