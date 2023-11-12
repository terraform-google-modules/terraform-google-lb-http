# Upgrading to v10.0

The 10.0 release contains backwards-incompatible changes.

---

### use_ssl_certificates is replaced with create_ssl_certificate

The `use_ssl_certificates` parameter has been removed. A new parameter `create_ssl_certificate` has been added. You can now create a load balancer with multiple certificates using certificate manager map or certificates (self managed, google managed)

In order to create https load balancer you need to pass `ssl = true` and at least one of the following:

1) list of self links to your own certificates passed to `ssl_certificates` OR
2) `create_ssl_certificate` set to `true` and `private_key/certificate` OR
3) list of domains for `managed_ssl_certificate_domains`, OR
4) Managed certificate using certificate manager by passing `certificate_map`

Load balancer allows Either 1,2,3 or option 4

---
See example [user-managed-google-managed-ssl](/examples/user-managed-google-managed-ssl) for combination of `option 1,2,3` where root module will pass self link to certificates, private key/Pem and domain for google managed certificates. You can now attach google managed certificates and user managed certificates to the load balancer at the same time.


```diff
module "gce-lb-https" {
-  source            = "GoogleCloudPlatform/lb-http/google"
-  version           = "~> 9.0"
+  source            = "GoogleCloudPlatform/lb-http/google"
+  version           = "~> 10.0"
-  use_ssl_certificates            = false
+  create_ssl_certificate          = true
  ssl                             = true
  private_key                     = tls_private_key.single_key.private_key_pem
  certificate                     = tls_self_signed_cert.single_cert.cert_pem
  managed_ssl_certificate_domains = ["test.example.com"]
  ssl_certificates                = google_compute_ssl_certificate.example.*.self_link
```

Here is an example of how to pass list of self managed certificates and domain for google managed certificates. Leave pem/certificate parameter empty


```diff
module "gce-lb-https" {
-  source            = "GoogleCloudPlatform/lb-http/google"
-  version           = "~> 9.0"
+  source            = "GoogleCloudPlatform/lb-http/google"
+  version           = "~> 10.0"
-  use_ssl_certificates            = false
+  create_ssl_certificate          = false
  ssl                             = true
  managed_ssl_certificate_domains = ["test.example.com"]
  ssl_certificates                = google_compute_ssl_certificate.example.*.self_link
```

---

See example [certificate-map](/examples/certificate-map) for `option 4` where root module will pass certificate map

```diff
module "gce-lb-https" {
-  source            = "GoogleCloudPlatform/lb-http/google"
-  version           = "~> 9.0"
+  source            = "GoogleCloudPlatform/lb-http/google"
+  version           = "~> 10.0"
-  use_ssl_certificates    = false
+  create_ssl_certificate  = false
  ssl                      = true
  certificate_map          = var.cert_map_name
```
