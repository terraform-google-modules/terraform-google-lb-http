# Upgrading from LB HTTP v2.0.0 to v3.0.0

### Process

This upgrade will require changing the input of your lb-http module to conform to the new group structure. There are also several
additions you may add, including:

* `address` and `create_address` - Allows you existing IPs to be used
* `ssl_policy`- Allows you to pass in your own SSL Policy
* `quic` - Allows you to enable QUIC support

### Input differences

The old version of `terraform-google-lb-http` had a list of backends and comma-separated `backend_params`

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

The new version allows you to specify all of your backend configuration, including groups and health checks into one object:

```HCL
module "gce-lb-http" {
  source            = "GoogleCloudPlatform/lb-http/google"
 version           = "3.0.0"

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

## Dealing with Dependencies

When migrating you may run into errors that look something like this:

```
Error: Error reading BackendService: googleapi: Error 400: The backend_service
resource 'projects/[PROJECT]/global/backendServices/multi-mig-lb-http-backend-0'
is already being used by 'projects/[PROJECT]/global/urlMaps/multi-mig-lb-http-url-map',
resourceInUseByAnotherResource



Error: Error reading HttpHealthCheck: googleapi: Error 400: The http_health_check
resource 'projects/[PROJECT]/global/httpHealthChecks/multi-mig-lb-http-backend-0'
is already being used by 'projects/[PROJECT]/global/backendServices/multi-mig-lb-http-backend-0',
resourceInUseByAnotherResource
```

The reason for this is that when we are changing the backend service and health check around, then must be destroyed and then re-created.
The dependencies here are as follows:

`global_forwarding_rule` -> `target_http_proxy` -> `url_map` -> `backend_service` -> `http_health_check`

Meaning if you want to change the things on the right, you first have to remove the dependency on the left. There are a few different ways of doing this.

### Method 1 - Destroy dependencies and re-apply

If this is a test project that is not used by anyone, simply destroy the dependencies and re-apply. For example, if your module is called `gce-lb-http`:

```
terraform destroy -target=module.gce-lb-http.google_compute_global_forwarding_rule.http[0]
terraform destroy -target=module.gce-lb-http.google_compute_target_http_proxy.default[0]
terraform destroy -target=module.gce-lb-http.google_compute_url_map.default[0]
terraform apply
```

### Method 2 - Non-destructive

For this, you'll have to first ensure the name of the backend service and healthcheck (i.e. the key for each backend in the `backends` variable) are different than they were before the migration. For this example, I'm changing the name from `"0"` to `"default"`.

First run `terraform apply`. It will error out but still create the backend, not affecting your existing URL map.

In the plan output you should see a change statement that looks something like this:

```
~ resource "google_compute_url_map" "default" {
        creation_timestamp = "2019-11-20T16:02:04.597-08:00"
      ~ default_service    = "https://www.googleapis.com/compute/v1/projects/[PROJECT]/global/backendServices/multi-mig-lb-http-backend-0" -> "https://www.googleapis.com/compute/v1/projects/[PROJECT]/global/backendServices/multi-mig-lb-http-backend-default"
```

Due to the way URL maps and Backends are interdependent in GCP, Terraform ends up ordering the API call to update url_map after the backend deleted, which triggers the above error. You can solve this by manually updating the default service for the url map using `gcloud`. Copy the value in the `default_service` attribute from your plan after the `~>` symbol. This is the value Terraform is planning to update it to. In this example:

```
gcloud compute url-maps set-default-service multi-mig-lb-http-url-map \
  --default-service=https://www.googleapis.com/compute/v1/projects/[PROJECT]/global/backendServices/multi-mig-lb-http-backend-default
```

This will cut over your URL map to the new service. After that you'll only need to run `terraform apply` twice more to destroy the old backend and healthcheck resources. You'll do it twice because the backend takes a second to go away and the healthcheck can't be destroyed until the resources using it are also destroyed.
