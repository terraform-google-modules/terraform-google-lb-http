# Global HTTP Load Balancer Terraform Module

Modular Global HTTP Load Balancer for GCE using forwarding rules.

{% if root %}

- If you would like to allow for backend groups to be managed outside Terraform,
  such as via GKE services, see the [dynamic
  backends](./modules/dynamic_backends) submodule.
- If you would like to use load balancing with serverless backends (Cloud Run,
  Cloud Functions or App Engine), see the
  [serverless_negs](./modules/serverless_negs) submodule and
  [cloudrun](./examples/cloudrun) example.

{% elif dynamic_backends %}
This submodule allows for configuring dynamic backend outside Terraform.
As such, any changes to the `backends.groups` variable after creation will be ignored.
{% endif %}

{# TCP LB and ILB don't work for Serverless NEGs yet. #}

## Load Balancer Types

- [TCP load balancer](https://github.com/terraform-google-modules/terraform-google-lb)
- **HTTP/S load balancer**
- [Internal load balancer](https://github.com/terraform-google-modules/terraform-google-lb-internal)

## Compatibility

This module is meant for use with Terraform 0.13+ and tested using Terraform 1.0+. If you find incompatibilities using Terraform >=0.13, please open an issue. If you haven't
[upgraded](https://www.terraform.io/upgrade-guides/0-13.html) and need a Terraform
0.12.x-compatible version of this module, the last released version
intended for Terraform 0.12.x is [v4.5.0](https://registry.terraform.io/modules/GoogleCloudPlatform/lb-http/google/4.5.0).

## Usage

```HCL
module "gce-lb-http" {
  source            = "GoogleCloudPlatform/lb-http/google{{ module_path }}"
  version           = "~> 4.4"

  project           = "my-project-id"
  name              = "my-lb"

  ssl                             = true
  managed_ssl_certificate_domains = ["your-domain.com"]
  https_redirect                  = true
  name                            = "group-http-lb"
  target_tags                     = [module.mig1.target_tags, module.mig2.target_tags]
  backends = {
    default = {
      description                     = null
      port                            = var.service_port
      protocol                        = "HTTP"
      port_name                       = var.service_port_name
      timeout_sec                     = 10
      enable_cdn                      = false
      custom_request_headers          = null
      custom_response_headers         = null
      security_policy                 = null
      compression_mode                = null

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

**Figure 1.** _diagram of terraform resources_

![architecture diagram](/diagram.png)

## Version

Current version is 9.0. Upgrade guides:

- [2.X -> 3.0](/docs/upgrading-v2.0.0-v3.0.0.md)
- [3.X -> 4.0](/docs/upgrading_to_v4.0.md)
- [6.X -> 7.0](/docs/upgrading_to_v7.0.md)
- [7.X -> 8.0](/docs/upgrading_to_v8.0.md)
- [8.X -> 9.0](/docs/upgrading_to_v9.0.md)


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Inputs

| Name                    | Description                                                                                                                                |     Type     |  Default  | Required |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | :----------: | :-------: | :------: |
| address                 | IPv4 address (actual IP address value)                                                                                                     |    string    | `"null"`  |    no    |
| ipv6_address            | IPv6 address (actual IP address value)                                                                                                     |    string    | `"null"`  |    no    |
| backends                | Map backend indices to list of backend maps.                                                                                               |    object    |    n/a    |   yes    |
| cdn                     | Set to `true` to enable cdn on backend.                                                                                                    |     bool     | `"false"` |    no    |
| certificate             | Content of the SSL certificate. Required if `ssl` is `true` and `ssl_certificates` is empty.                                               |    string    | `"null"`  |    no    |
| certificate\_map        | Certificate Map ID in format projects/{project}/locations/global/certificateMaps/{{name}}. Identifies a certificate map associated with the given target proxy | `string` | `null` | no |
| create_address          | Create a new global IPv4 address                                                                                                           |     bool     | `"true"`  |    no    |
| create_ipv6_address     | Create a new global IPv6 address                                                                                                           |     bool     | `"true"`  |    no    |
| create_url_map          | Set to `false` if url_map variable is provided.                                                                                            |     bool     | `"true"`  |    no    |
| firewall_networks       | Names of the networks to create firewall rules in                                                                                          | list(string) | `<list>`  |    no    |
| firewall_projects       | Names of the projects to create firewall rules in                                                                                          | list(string) | `<list>`  |    no    |
| http_forward            | Set to `false` to disable HTTP port 80 forward                                                                                             |     bool     | `"true"`  |    no    |
| https_redirect          | Set to `true` to enable https redirect on the lb.                                                                                          |     bool     | `"false"` |    no    |
| name                    | Name for the forwarding rule and prefix for supporting resources                                                                           |    string    |    n/a    |   yes    |
| private_key             | Content of the private SSL key. Required if `ssl` is `true` and `ssl_certificates` is empty.                                               |    string    | `"null"`  |    no    |
| project                 | The project to deploy to, if not set the default provider project is used.                                                                 |    string    |    n/a    |   yes    |
| quic                    | Set to `true` to enable QUIC support                                                                                                       |     bool     | `"false"` |    no    |
| security_policy         | The resource URL for the security policy to associate with the backend service                                                             |    string    | `"null"`  |    no    |
| ssl                     | Set to `true` to enable SSL support, requires variable `ssl_certificates` - a list of self_link certs                                      |     bool     | `"false"` |    no    |
| ssl_certificates        | SSL cert self_link list. Required if `ssl` is `true` and no `private_key` and `certificate` is provided.                                   | list(string) | `<list>`  |    no    |
| ssl_policy              | Selfink to SSL Policy                                                                                                                      |    string    | `"null"`  |    no    |
| target_service_accounts | List of target service accounts for health check firewall rule. Exactly one of target_tags or target_service_accounts should be specified. | list(string) | `<list>`  |    no    |
| target_tags             | List of target tags for health check firewall rule. Exactly one of target_tags or target_service_accounts should be specified.             | list(string) | `<list>`  |    no    |
| url_map                 | The url_map resource to use. Default is to send all traffic to first backend.                                                              |    string    | `"null"`  |    no    |
| use_ssl_certificates    | If true, use the certificates provided by `ssl_certificates`, otherwise, create cert from `private_key` and `certificate`                  |     bool     | `"false"` |    no    |

## Outputs

| Name                  | Description                                                      |
| --------------------- | ---------------------------------------------------------------- |
| backend_services      | The backend service resources.                                   |
| external_ip           | The external IPv4 address assigned to the global fowarding rule. |
| external_ipv6_address | The external IPv6 address assigned to the global fowarding rule. |
| http_proxy            | The HTTP proxy used by this module.                              |
| https_proxy           | The HTTPS proxyused by this module.                              |

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
