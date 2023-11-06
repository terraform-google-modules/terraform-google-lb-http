# Upgrading to v10.0

The 10.0 release contains backwards-incompatible changes.

---

The `use_ssl_certificates` parameter has been removed. A new parmater `create_ssl_certificate` has been added. 

In order to create https load balancer you need to pass `ssl = true` and one of the following:

1) list of self links to your own certificates passed to`ssl_certificates` OR 
2) `create_ssl_certificate` set to `true` and `private_key/certificate` OR  
3) list of domains for `managed_ssl_certificate_domains`, OR 
4) Managed certificate using certificate manager by passing `certificate_map`

Load balancer allows Either 1,2,3 or option 4

---
See example [user-managed-google-managed-ssl](/examples/user-managed-google-managed-ssl) for combination of `option 1,2,3` where root module will pass self link to certificates, private key/Pem and domain for google managed certificates
See example [certificate-map](/examples/certificate-map) for `option 4` where root module will pass certificate map