# Upgrading to v4.0

The v4.0 release contains backwards-incompatible
changes to the backend config.

## Backend Config

`session_affinity`, `affinity_cookie_ttl_sec`, and `log_config` must now be specified
for backends. To use the default value, specify `null`.

```diff
  module "gce-lb-http" {
    source            = "GoogleCloudPlatform/lb-http/google"
-   version           = "~> 3.1"
+   version           = "~> 4.0"

    backends = {
      default = {
        description                     = null
        protocol                        = "HTTP"
        port                            = var.service_port
        port_name                       = var.service_port_name
        timeout_sec                     = 10
        connection_draining_timeout_sec = null
        enable_cdn                      = false
+       session_affinity                = null
+       affinity_cookie_ttl_sec         = null
+       log_config                      = null

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
