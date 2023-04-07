# Global HTTP Load Balancer Terraform Module for Serverless NEGs

This submodule allows you to create Cloud HTTP(S) Load Balancer with
[Serverless Network Endpoint Groups (NEGs)](https://cloud.google.com/load-balancing/docs/negs/serverless-neg-concepts)
and place serverless services from Cloud Run, Cloud Functions and App Engine
behind a Cloud Load Balancer.


## Compatibility

This module is meant for use with Terraform 0.13+ and tested using Terraform 1.0+. If you find incompatibilities using Terraform >=0.13, please open an issue. If you haven't
[upgraded](https://www.terraform.io/upgrade-guides/0-13.html) and need a Terraform
0.12.x-compatible version of this module, the last released version
intended for Terraform 0.12.x is [v4.5.0](https://registry.terraform.io/modules/GoogleCloudPlatform/lb-http/google/4.5.0).

## Usage

```HCL
module "lb-http" {
  source            = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version           = "~> 4.4"

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


## Version

Current version is 3.0. Upgrade guides:

- [1.X -> 2.X](https://www.terraform.io/upgrade-guides/0-12.html)
- [2.X -> 3.0](/docs/upgrading-v2.0.0-v3.0.0.md)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Inputs

| Name                    | Description                                                                                                                                |     Type     |  Default  | Required |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | :----------: | :-------: | :------: |
| address                 | IPv4 address (actual IP address value)                                                                                                     |    string    | `"null"`  |    no    |
| ipv6_address            | IPv6 address (actual IP address value)                                                                                                     |    string    | `"null"`  |    no    |
| backends                | Map backend indices to list of backend maps.                                                                                               |    object    |    n/a    |   yes    |
| cdn                     | Set to `true` to enable cdn on backend.                                                                                                    |     bool     | `"false"` |    no    |
| certificate             | Content of the SSL certificate. Required if `ssl` is `true` and `ssl_certificates` is empty.                                               |    string    | `"null"`  |    no    |
| certificate\_map        | Certificate Map ID in format projects/{project}/locations/global/certificateMaps/. Identifies a certificate map associated with the given target proxy | `string` | `null` | no |
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
