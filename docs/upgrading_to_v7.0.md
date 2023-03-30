# Upgrading to v7.0

The v7.0 release contains backwards-incompatible changes to the backend config.

## Added support for `compression_mode`.

`compression_mode` must now be specified for backends. To use the default value, specify `null`.

```diff
  module "gce-lb-http" {
    source            = "GoogleCloudPlatform/lb-http/google"
-   version           = "~> 6.3.0"
+   version           = "~> 7.0"

    backends = {
      default = {
+       compression_mode = null
...
      }
    }
  }
```

## Added support for `port` and `protocol` in `serverless_negs` module.

`port` and `protocol` must now be specified for backends in `serverless_negs`.
To use the default value (`http`), specify `null`.

```diff
  module "gce-lb-http" {
    source            = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
-   version           = "~> 6.3.0"
+   version           = "~> 7.0"

    backends = {
      default = {
+       port_name = null
+       protocol  = null
...
      }
    }
  }
```
