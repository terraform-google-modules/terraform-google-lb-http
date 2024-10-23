# HTTP Load balancer backend module

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| affinity\_cookie\_ttl\_sec | n/a | `number` | `null` | no |
| cdn\_policy | n/a | <pre>object({<br>    cache_mode                      = optional(string)<br>    signed_url_cache_max_age_sec    = optional(string)<br>    default_ttl                     = optional(number)<br>    max_ttl                         = optional(number)<br>    client_ttl                      = optional(number)<br>    negative_caching                = optional(bool)<br>    serve_while_stale               = optional(number)<br>    bypass_cache_on_request_headers = optional(list(string))<br>    negative_caching_policy = optional(object({<br>      code = optional(number)<br>      ttl  = optional(number)<br>    }))<br>    cache_key_policy = optional(object({<br>      include_host           = optional(bool)<br>      include_protocol       = optional(bool)<br>      include_query_string   = optional(bool)<br>      query_string_blacklist = optional(list(string))<br>      query_string_whitelist = optional(list(string))<br>      include_http_headers   = optional(list(string))<br>      include_named_cookies  = optional(list(string))<br>    }))<br>  })</pre> | `{}` | no |
| compression\_mode | n/a | `string` | `"DISABLED"` | no |
| connection\_draining\_timeout\_sec | n/a | `number` | `null` | no |
| custom\_request\_headers | n/a | `list(string)` | `[]` | no |
| custom\_response\_headers | n/a | `list(string)` | `[]` | no |
| description | n/a | `string` | `null` | no |
| edge\_security\_policy | The resource URL for the edge security policy to associate with the backend service | `string` | `null` | no |
| enable\_cdn | n/a | `bool` | `false` | no |
| firewall\_networks | Names of the networks to create firewall rules in | `list(string)` | <pre>[<br>  "default"<br>]</pre> | no |
| firewall\_projects | Names of the projects to create firewall rules in | `list(string)` | <pre>[<br>  "default"<br>]</pre> | no |
| groups | n/a | <pre>list(object({<br>    group       = string<br>    description = optional(string)<br>  }))</pre> | `[]` | no |
| health\_check | n/a | <pre>object({<br>    host                = optional(string, null)<br>    request_path        = optional(string, null)<br>    request             = optional(string, null)<br>    response            = optional(string, null)<br>    port                = optional(number, null)<br>    port_name           = optional(string, null)<br>    proxy_header        = optional(string, null)<br>    port_specification  = optional(string, null)<br>    protocol            = optional(string, null)<br>    check_interval_sec  = optional(number, 5)<br>    timeout_sec         = optional(number, 5)<br>    healthy_threshold   = optional(number, 2)<br>    unhealthy_threshold = optional(number, 2)<br>    logging             = optional(bool, false)<br>  })</pre> | `null` | no |
| host\_path\_mappings | The list of host/path for which traffic could be sent to the backend service | `list(object({ host : string, path : string }))` | <pre>[<br>  {<br>    "host": "*",<br>    "path": "/*"<br>  }<br>]</pre> | no |
| iap\_config | n/a | <pre>object({<br>    enable               = bool<br>    oauth2_client_id     = optional(string)<br>    oauth2_client_secret = optional(string)<br>  })</pre> | <pre>{<br>  "enable": false<br>}</pre> | no |
| load\_balancing\_scheme | Load balancing scheme type (EXTERNAL for classic external load balancer, EXTERNAL\_MANAGED for Envoy-based load balancer, and INTERNAL\_SELF\_MANAGED for traffic director) | `string` | `"EXTERNAL_MANAGED"` | no |
| locality\_lb\_policy | n/a | `string` | `null` | no |
| log\_config | n/a | <pre>object({<br>    enable      = bool<br>    sample_rate = number<br>  })</pre> | <pre>{<br>  "enable": true,<br>  "sample_rate": 1<br>}</pre> | no |
| name | Name for the backend service | `string` | n/a | yes |
| outlier\_detection | n/a | <pre>object({<br>    base_ejection_time = optional(object({<br>      seconds = number<br>      nanos   = optional(number)<br>    }))<br>    consecutive_errors                    = optional(number)<br>    consecutive_gateway_failure           = optional(number)<br>    enforcing_consecutive_errors          = optional(number)<br>    enforcing_consecutive_gateway_failure = optional(number)<br>    enforcing_success_rate                = optional(number)<br>    interval = optional(object({<br>      seconds = number<br>      nanos   = optional(number)<br>    }))<br>    max_ejection_percent        = optional(number)<br>    success_rate_minimum_hosts  = optional(number)<br>    success_rate_request_volume = optional(number)<br>    success_rate_stdev_factor   = optional(number)<br>  })</pre> | `null` | no |
| port\_name | n/a | `string` | `"http"` | no |
| project\_id | The project to deploy to, if not set the default provider project is used. | `string` | n/a | yes |
| protocol | n/a | `string` | `"HTTP"` | no |
| security\_policy | The resource URL for the security policy to associate with the backend service | `string` | `null` | no |
| serverless\_neg\_backends | n/a | <pre>list(object({<br>    region          = string<br>    type            = string // cloud-run, cloud-function, and app-engine<br>    service_name    = string<br>    service_version = optional(string)<br>  }))</pre> | `[]` | no |
| session\_affinity | n/a | `string` | `null` | no |
| target\_service\_accounts | List of target service accounts for health check firewall rule. Exactly one of target\_tags or target\_service\_accounts should be specified. | `list(string)` | `[]` | no |
| target\_tags | List of target tags for health check firewall rule. Exactly one of target\_tags or target\_service\_accounts should be specified. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| backend\_service\_info | Host, path and backend service mapping |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->