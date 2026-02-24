# HTTP Load balancer frontend module
This module creates `HTTP(S) forwarding rule` and its dependencies. This modules doesn't create `google_compute_backend_service` which can be created by using `modules/frontend`. The separation of the modules makes it easier for creating backend and frontend resources independent of each other. The logical separation helps in improved maintainability.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| address | Existing IPv4 address to use (the actual IP address value) | `string` | `null` | no |
| certificate | Content of the SSL certificate. Requires `ssl` to be set to `true` and `create_ssl_certificate` set to `true` | `string` | `null` | no |
| certificate\_map | Certificate Map ID in format projects/{project}/locations/global/certificateMaps/{name}. Identifies a certificate map associated with the given target proxy.  Requires `ssl` to be set to `true` | `string` | `null` | no |
| create\_address | Create a new global IPv4 address | `bool` | `true` | no |
| create\_ipv6\_address | Allocate a new IPv6 address. Conflicts with "ipv6\_address" - if both specified, "create\_ipv6\_address" takes precedence. | `bool` | `false` | no |
| create\_ssl\_certificate | If `true`, Create certificate using `private_key/certificate` | `bool` | `false` | no |
| create\_url\_map | Set to `false` if url\_map variable is provided. | `bool` | `true` | no |
| enable\_ipv6 | Enable IPv6 address on the CDN load-balancer | `bool` | `false` | no |
| http\_forward | Set to `false` to disable HTTP port 80 forward | `bool` | `true` | no |
| http\_keep\_alive\_timeout\_sec | Specifies how long to keep a connection open, after completing a response, while there is no matching traffic (in seconds). | `number` | `null` | no |
| http\_port | The port for the HTTP load balancer | `number` | `80` | no |
| https\_port | The port for the HTTPS load balancer | `number` | `443` | no |
| https\_redirect | Set to `true` to enable https redirect on the lb. | `bool` | `false` | no |
| internal\_forwarding\_rules\_config | List of internal managed forwarding rules config. One of 'address' or 'subnetwork' is required for each. It is only applicable for internal load balancer | <pre>list(object({<br>    region     = string<br>    address    = optional(string)<br>    subnetwork = optional(string)<br>  }))</pre> | `[]` | no |
| ipv6\_address | An existing IPv6 address to use (the actual IP address value) | `string` | `null` | no |
| labels | The labels to attach to resources created by this module | `map(string)` | `{}` | no |
| load\_balancing\_scheme | Load balancing scheme type (EXTERNAL for classic external load balancer, EXTERNAL\_MANAGED for Envoy-based load balancer, INTERNAL\_MANAGED for internal load balancer and INTERNAL\_SELF\_MANAGED for traffic director) | `string` | `"EXTERNAL_MANAGED"` | no |
| managed\_ssl\_certificate\_domains | Create Google-managed SSL certificates for specified domains. Requires `ssl` to be set to `true` | `list(string)` | `[]` | no |
| name | Name for the forwarding rule and prefix for supporting resources | `string` | n/a | yes |
| network | VPC network for the forwarding rule. The VPC network should have exactly one GLOBAL\_MANAGED\_PROXY subnetwork for every region where the forwarding rule is to be configured. Please go to the subnets tab of your VPC network and check if a GLOBAL\_MANAGED\_PROXY subnet exists under the `Reserved proxy-only subnets for load balancing` section. If a GLOBAL\_MANAGED\_PROXY subnet doesn't exist, create one for each required region. | `string` | `"default"` | no |
| network\_tier | Network tier for the forwarding rule. | `string` | `null` | no |
| private\_key | Content of the private SSL key. Requires `ssl` to be set to `true` and `create_ssl_certificate` set to `true` | `string` | `null` | no |
| project\_id | The project to deploy to, if not set the default provider project is used. | `string` | n/a | yes |
| quic | Specifies the QUIC override policy for this resource. Set true to enable HTTP/3 and Google QUIC support, false to disable both. Defaults to null which enables support for HTTP/3 only. | `bool` | `null` | no |
| random\_certificate\_suffix | Bool to enable/disable random certificate name generation. Set and keep this to true if you need to change the SSL cert. | `bool` | `false` | no |
| server\_tls\_policy | The resource URL for the server TLS policy to associate with the https proxy service | `string` | `null` | no |
| ssl | Set to `true` to enable SSL support. If `true` then at least one of these are required: 1) `ssl_certificates` OR 2) `create_ssl_certificate` set to `true` and `private_key/certificate` OR  3) `managed_ssl_certificate_domains`, OR 4) `certificate_map` | `bool` | `false` | no |
| ssl\_certificates | SSL cert self\_link list. Requires `ssl` to be set to `true` | `list(string)` | `[]` | no |
| ssl\_policy | Selfink to SSL Policy | `string` | `null` | no |
| url\_map\_input | List of host, path and backend service for creating url\_map | <pre>list(object({<br>    host            = string<br>    path            = string<br>    backend_service = string<br>  }))</pre> | `[]` | no |
| url\_map\_resource\_uri | The url\_map resource to use. Default is to send all traffic to first backend. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| apphub\_service\_uri | Service URI in CAIS style to be used by Apphub. |
| external\_ip | The external IPv4 assigned to the global fowarding rule. |
| external\_ipv6\_address | The external IPv6 assigned to the global fowarding rule. |
| http\_proxy | The HTTP proxy used by this module. |
| https\_proxy | The HTTPS proxy used by this module. |
| ip\_address\_internal\_managed\_http | The internal/external IP addresses assigned to the HTTP forwarding rules. |
| ip\_address\_internal\_managed\_https | The internal/external IP addresses assigned to the HTTPS forwarding rules. |
| ipv6\_enabled | Whether IPv6 configuration is enabled on this load-balancer |
| ssl\_certificate\_created | The SSL certificate create from key/pem |
| url\_map | The default URL map used by this module. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
