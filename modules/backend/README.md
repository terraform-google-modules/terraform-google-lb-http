# HTTP Load balancer backend module
This module creates `google_compute_backend_service` resource and its dependencies. This module can be used with `modules/frontend`. The separation of the modules makes it easier for creating backend and frontend resources independent of each other. The logical separation helps in improved maintainability.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| affinity\_cookie\_ttl\_sec | Lifetime of cookies in seconds if session\_affinity is GENERATED\_COOKIE. | `number` | `null` | no |
| backend\_bucket\_name | The name of GCS bucket which serves the traffic. | `string` | `""` | no |
| cdn\_policy | Cloud CDN configuration for this BackendService. | <pre>object({<br>    cache_mode                      = optional(string)<br>    signed_url_cache_max_age_sec    = optional(string)<br>    default_ttl                     = optional(number)<br>    max_ttl                         = optional(number)<br>    client_ttl                      = optional(number)<br>    negative_caching                = optional(bool)<br>    serve_while_stale               = optional(number)<br>    bypass_cache_on_request_headers = optional(list(string))<br>    negative_caching_policy = optional(object({<br>      code = optional(number)<br>      ttl  = optional(number)<br>    }))<br>    cache_key_policy = optional(object({<br>      include_host           = optional(bool)<br>      include_protocol       = optional(bool)<br>      include_query_string   = optional(bool)<br>      query_string_blacklist = optional(list(string))<br>      query_string_whitelist = optional(list(string))<br>      include_http_headers   = optional(list(string))<br>      include_named_cookies  = optional(list(string))<br>    }))<br>  })</pre> | <pre>{<br>  "cache_mode": "CACHE_ALL_STATIC",<br>  "client_ttl": 3600,<br>  "default_ttl": 3600,<br>  "max_ttl": 86400,<br>  "signed_url_cache_max_age_sec": "0"<br>}</pre> | no |
| compression\_mode | Compress text responses using Brotli or gzip compression. | `string` | `"DISABLED"` | no |
| connection\_draining\_timeout\_sec | Time for which instance will be drained (not accept new connections, but still work to finish started). | `number` | `null` | no |
| custom\_request\_headers | Headers that the HTTP/S load balancer should add to proxied requests. | `list(string)` | `[]` | no |
| custom\_response\_headers | Headers that the HTTP/S load balancer should add to proxied responses. | `list(string)` | `[]` | no |
| description | Description of the backend service. | `string` | `null` | no |
| edge\_security\_policy | The resource URL for the edge security policy to associate with the backend service | `string` | `null` | no |
| enable\_cdn | Enable Cloud CDN for this BackendService. | `bool` | `false` | no |
| firewall\_networks | Names of the networks to create firewall rules in | `list(string)` | <pre>[<br>  "default"<br>]</pre> | no |
| firewall\_projects | Names of the projects to create firewall rules in | `list(string)` | <pre>[<br>  "default"<br>]</pre> | no |
| firewall\_source\_ranges | Source ranges for the global Application Load Balancer's proxies. This list should contain the `ip_cidr_range` of each GLOBAL\_MANAGED\_PROXY subnet. | `list(string)` | <pre>[<br>  "10.127.0.0/23"<br>]</pre> | no |
| groups | The list of backend instance group which serves the traffic. | <pre>list(object({<br>    group       = string<br>    description = optional(string)<br><br>    balancing_mode               = optional(string)<br>    capacity_scaler              = optional(number)<br>    max_connections              = optional(number)<br>    max_connections_per_instance = optional(number)<br>    max_connections_per_endpoint = optional(number)<br>    max_rate                     = optional(number)<br>    max_rate_per_instance        = optional(number)<br>    max_rate_per_endpoint        = optional(number)<br>    max_utilization              = optional(number)<br>  }))</pre> | `[]` | no |
| health\_check | Input for creating HttpHealthCheck or HttpsHealthCheck resource for health checking this BackendService. A health check must be specified unless the backend service uses an internet or serverless NEG as a backend. | <pre>object({<br>    host                = optional(string, null)<br>    request_path        = optional(string, null)<br>    request             = optional(string, null)<br>    response            = optional(string, null)<br>    port                = optional(number, null)<br>    port_name           = optional(string, null)<br>    proxy_header        = optional(string, null)<br>    port_specification  = optional(string, null)<br>    protocol            = optional(string, null)<br>    check_interval_sec  = optional(number, 5)<br>    timeout_sec         = optional(number, 5)<br>    healthy_threshold   = optional(number, 2)<br>    unhealthy_threshold = optional(number, 2)<br>    logging             = optional(bool, false)<br>  })</pre> | `null` | no |
| host\_path\_mappings | The list of host/path for which traffic could be sent to the backend service | <pre>list(object({<br>    host = string<br>    path = string<br>  }))</pre> | <pre>[<br>  {<br>    "host": "*",<br>    "path": "/*"<br>  }<br>]</pre> | no |
| iap\_config | Settings for enabling Cloud Identity Aware Proxy and Users/SAs to be given IAP HttpResourceAccessor access to the service. | <pre>object({<br>    enable               = bool<br>    oauth2_client_id     = optional(string)<br>    oauth2_client_secret = optional(string)<br>    iap_members          = optional(list(string))<br>  })</pre> | <pre>{<br>  "enable": false<br>}</pre> | no |
| load\_balancing\_scheme | Load balancing scheme type (EXTERNAL for classic external load balancer, EXTERNAL\_MANAGED for Envoy-based load balancer, INTERNAL\_MANAGED for internal load balancer and INTERNAL\_SELF\_MANAGED for traffic director) | `string` | `"EXTERNAL_MANAGED"` | no |
| locality\_lb\_policy | The load balancing algorithm used within the scope of the locality. | `string` | `null` | no |
| log\_config | This field denotes the logging options for the load balancer traffic served by this backend service. If logging is enabled, logs will be exported to Stackdriver. | <pre>object({<br>    enable      = bool<br>    sample_rate = number<br>  })</pre> | <pre>{<br>  "enable": true,<br>  "sample_rate": 1<br>}</pre> | no |
| name | Name for the backend service. | `string` | n/a | yes |
| outlier\_detection | Settings controlling eviction of unhealthy hosts from the load balancing pool. | <pre>object({<br>    base_ejection_time = optional(object({<br>      seconds = number<br>      nanos   = optional(number)<br>    }))<br>    consecutive_errors                    = optional(number)<br>    consecutive_gateway_failure           = optional(number)<br>    enforcing_consecutive_errors          = optional(number)<br>    enforcing_consecutive_gateway_failure = optional(number)<br>    enforcing_success_rate                = optional(number)<br>    interval = optional(object({<br>      seconds = number<br>      nanos   = optional(number)<br>    }))<br>    max_ejection_percent        = optional(number)<br>    success_rate_minimum_hosts  = optional(number)<br>    success_rate_request_volume = optional(number)<br>    success_rate_stdev_factor   = optional(number)<br>  })</pre> | `null` | no |
| port\_name | Name of backend port. The same name should appear in the instance groups referenced by this service. Required when the load balancing scheme is EXTERNAL. | `string` | `"http"` | no |
| project\_id | The project to deploy to, if not set the default provider project is used. | `string` | n/a | yes |
| protocol | The protocol this BackendService uses to communicate with backends. | `string` | `"HTTP"` | no |
| security\_policy | The resource URL for the security policy to associate with the backend service | `string` | `null` | no |
| serverless\_neg\_backends | The list of serverless backend which serves the traffic. | <pre>list(object({<br>    region          = string<br>    type            = string // cloud-run, cloud-function, and app-engine<br>    service_name    = string<br>    service_version = optional(string)<br>  }))</pre> | `[]` | no |
| session\_affinity | Type of session affinity to use. Possible values are: NONE, CLIENT\_IP, CLIENT\_IP\_PORT\_PROTO, CLIENT\_IP\_PROTO, GENERATED\_COOKIE, HEADER\_FIELD, HTTP\_COOKIE, STRONG\_COOKIE\_AFFINITY. | `string` | `null` | no |
| target\_service\_accounts | List of target service accounts for health check firewall rule. Exactly one of target\_tags or target\_service\_accounts should be specified. | `list(string)` | `[]` | no |
| target\_tags | List of target tags for health check firewall rule. Exactly one of target\_tags or target\_service\_accounts should be specified. | `list(string)` | `[]` | no |
| timeout\_sec | This has different meaning for different type of load balancing. Please refer https://cloud.google.com/load-balancing/docs/backend-service#timeout-setting | `number` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| apphub\_service\_uri | Service URI in CAIS style to be used by Apphub. |
| backend\_service\_info | Host, path and backend service mapping |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
