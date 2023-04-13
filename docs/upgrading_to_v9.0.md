# Upgrading to v9.0

The v9.0 release contains backwards-incompatible changes.

This update requires upgrading the minimum provider version from `4.45` to `4.50`.

The [`edge_security_policy`](https://github.com/terraform-google-modules/terraform-google-lb-http/blob/cb15ed7391f1bbcc4fdb6d55ee5703ca0d47447a/variables.tf#L91) object attribute and its nested attributes within the [`backends`] variable (https://github.com/terraform-google-modules/terraform-google-lb-http/blob/cb15ed7391f1bbcc4fdb6d55ee5703ca0d47447a/variables.tf#L81) is now available. It is optional.

---

The [`quic`](https://github.com/terraform-google-modules/terraform-google-lb-http/blob/dfb6cdaf5681e59324294bb23f0e656e0f4847e6/variables.tf#L190) variable now takes `true`, `false`, or `null` which corresponds to HTTP/3 and Google QUIC being enabled, both disabled, and HTTP/3 enabled only. Defaults to `null`.
