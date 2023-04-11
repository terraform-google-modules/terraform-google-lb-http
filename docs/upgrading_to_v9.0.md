# Upgrading to v9.0

The v9.0 release contains backwards-incompatible changes.

This update requires upgrading the minimum provider version from `4.45` to `4.50`.

The [`edge_security_policy`](https://github.com/terraform-google-modules/terraform-google-lb-http/blob/cb15ed7391f1bbcc4fdb6d55ee5703ca0d47447a/variables.tf#L91) object attribute and its nested attributes within the [`backends`] variable (https://github.com/terraform-google-modules/terraform-google-lb-http/blob/cb15ed7391f1bbcc4fdb6d55ee5703ca0d47447a/variables.tf#L81) is now available. It is optional.
