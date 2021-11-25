# Global HTTP Load Balancer Terraform Module for static websites using a Cloud Storage Bucket

This submodule allows you to create a Cloud HTTP(S) Load Balancer for [static website content hosted in a Cloud Storage Bucket](https://cloud.google.com/storage/docs/hosting-static-website) with a CDN for content caching and distribution. Although multiple backend storage buckets are supported by the HTTP(s) LB, this module is limited to one backend currently.


## Compatibility

This module is meant for use with Terraform 0.13+ and tested using Terraform 1.0+. If you find incompatibilities using Terraform >=0.13, please open an issue. If you haven't
[upgraded](https://www.terraform.io/upgrade-guides/0-13.html) and need a Terraform
0.12.x-compatible version of this module, the last released version
intended for Terraform 0.12.x is [v4.5.0](https://registry.terraform.io/modules/GoogleCloudPlatform/lb-http/google/4.5.0).

## Usage

```HCL
module "gce-lb-http" {
  source            = "GoogleCloudPlatform/lb-http/google//modules/backend_bucket"
  version           = "~> 4.4"

  project           = "my-project-id"
  name              = "my-lb"

  ssl                             = true
  managed_ssl_certificate_domains = ["your-domain.com"]
  https_redirect                  = true

  bucket_name       = "your-storagebucket-name"
  enable_cdn        = true

  cdn_policy {
    cache_mode                   = var.cache_mode
    client_ttl                   = var.client_ttl
    default_ttl                  = var.default_ttl
    max_ttl                      = var.max_ttl
    negative_caching             = var.negative_caching
    signed_url_cache_max_age_sec = var.signed_url_cache_max_age_sec
  }

}
```


## Version

Current version is 3.0. Upgrade guides:

* [1.X -> 2.X](https://www.terraform.io/upgrade-guides/0-12.html)
* [2.X -> 3.0](./docs/upgrading-v2.0.0-v3.0.0.md)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| address | Existing IPv4 address to use (the actual IP address value) | `string` | `null` | no |
| bucket\_name | a string value representing the name of the cloud storage bucket for the backend | `string` | `null` | no |
| cache\_mode | a string representing the caching mode - options include USE\_ORIGIN\_HEADERS, FORCE\_CACHE\_ALL and CACHE\_ALL\_STATIC | `string` | `"CACHE_ALL_STATIC"` | no |
| certificate | Content of the SSL certificate. Required if `ssl` is `true` and `ssl_certificates` is empty. | `string` | `null` | no |
| client\_ttl | Specifies the maximum allowed TTL for cached content served by this origin. | `string` | `"3600"` | no |
| create\_address | Create a new global IPv4 address | `bool` | `true` | no |
| create\_ipv6\_address | Allocate a new IPv6 address. Conflicts with "ipv6\_address" - if both specified, "create\_ipv6\_address" takes precedence. | `bool` | `false` | no |
| create\_url\_map | Set to `false` if url\_map variable is provided. | `bool` | `true` | no |
| default\_ttl | Specifies the default TTL for cached content served by this origin for responses that do not have an existing valid TTL (max-age or s-max-age) | `string` | `"3600"` | no |
| enable\_cdn\_for\_bucket | Bool to enable/disable cdn on a backend storage bucket for static websites | `bool` | `true` | no |
| enable\_ipv6 | Enable IPv6 address on the CDN load-balancer | `bool` | `false` | no |
| http\_forward | Set to `false` to disable HTTP port 80 forward | `bool` | `true` | no |
| https\_redirect | Set to `true` to enable https redirect on the lb. | `bool` | `false` | no |
| ipv6\_address | An existing IPv6 address to use (the actual IP address value) | `string` | `null` | no |
| managed\_ssl\_certificate\_domains | Create Google-managed SSL certificates for specified domains. Requires `ssl` to be set to `true` and `use_ssl_certificates` set to `false`. | `list(string)` | `[]` | no |
| max\_ttl | Specifies the maximum allowed TTL for cached content served by this origin. | `string` | `"86400"` | no |
| name | Name for the forwarding rule and prefix for supporting resources | `string` | n/a | yes |
| negative\_caching | Negative caching allows per-status code TTLs to be set, in order to apply fine-grained caching for common errors or redirects | `bool` | `false` | no |
| private\_key | Content of the private SSL key. Required if `ssl` is `true` and `ssl_certificates` is empty. | `string` | `null` | no |
| project | The project to deploy to, if not set the default provider project is used. | `string` | n/a | yes |
| quic | Set to `true` to enable QUIC support | `bool` | `false` | no |
| random\_certificate\_suffix | Bool to enable/disable random certificate name generation. Set and keep this to true if you need to change the SSL cert. | `bool` | `false` | no |
| security\_policy | The resource URL for the security policy to associate with the backend service | `string` | `null` | no |
| signed\_url\_cache\_max\_age\_sec | Maximum number of seconds the response to a signed URL request will be considered fresh, defaults to 1hr (3600s). After this time period, the response will be revalidated before being served | `string` | `"7200"` | no |
| ssl | Set to `true` to enable SSL support, requires variable `ssl_certificates` - a list of self\_link certs | `bool` | `false` | no |
| ssl\_certificates | SSL cert self\_link list. Required if `ssl` is `true` and no `private_key` and `certificate` is provided. | `list(string)` | `[]` | no |
| ssl\_policy | Selfink to SSL Policy | `string` | `null` | no |
| url\_map | The url\_map resource to use. Default is to send all traffic to first backend. | `string` | `null` | no |
| use\_ssl\_certificates | If true, use the certificates provided by `ssl_certificates`, otherwise, create cert from `private_key` and `certificate` | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| backend\_bucket | The backend bucket resource. |
| external\_ip | The external IPv4 assigned to the global fowarding rule. |
| external\_ipv6\_address | The external IPv6 assigned to the global fowarding rule. |
| http\_proxy | The HTTP proxy used by this module. |
| https\_proxy | The HTTPS proxy used by this module. |
| ipv6\_enabled | Whether IPv6 configuration is enabled on this load-balancer |
| url\_map | The default URL map used by this module. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

* [`google_compute_global_forwarding_rule.http`](https://www.terraform.io/docs/providers/google/r/compute_global_forwarding_rule.html): The global HTTP forwarding rule.
* [`google_compute_global_forwarding_rule.https`](https://www.terraform.io/docs/providers/google/r/compute_global_forwarding_rule.html): The global HTTPS forwarding rule created when `ssl` is `true`.
* [`google_compute_target_http_proxy.default`](https://www.terraform.io/docs/providers/google/r/compute_target_http_proxy.html): The HTTP proxy resource that binds the url map. Created when input `ssl` is `false`.
* [`google_compute_target_https_proxy.default`](https://www.terraform.io/docs/providers/google/r/compute_target_https_proxy.html): The HTTPS proxy resource that binds the url map. Created when input `ssl` is `true`.
* [`google_compute_ssl_certificate.default`](https://www.terraform.io/docs/providers/google/r/compute_ssl_certificate.html): The certificate resource created when input `ssl` is `true` and `managed_ssl_certificate_domains` not specified.
* [`google_compute_managed_ssl_certificate.default`](https://www.terraform.io/docs/providers/google/r/compute_managed_ssl_certificate.html): The Google-managed certificate resource created when input `ssl` is `true` and `managed_ssl_certificate_domains` is specified.
* [`google_compute_url_map.default`](https://www.terraform.io/docs/providers/google/r/compute_url_map.html): The default URL map resource when input `url_map` is not provided.
* [`google_compute_backend_bucket.default.*`](https://www.terraform.io/docs/providers/google/r/compute_backend_bucket.html):
  The Backend cloud storage bucket used with HTTP(S) load balancing to serve static content, and its related CDN settings.
