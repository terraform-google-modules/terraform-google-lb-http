# Upgrading to v9.0

The v9.0 release contains backwards-incompatible changes.

### [Terraform](https://www.terraform.io/downloads.html) >= 1.3.0 is required as `edge_security_policy` and its nested attributes and objects are made optional in the `backends` object

The [`edge_security_policy`](https://github.com/terraform-google-modules/terraform-google-lb-http/blob/cb15ed7391f1bbcc4fdb6d55ee5703ca0d47447a/variables.tf#L91) object attribute and its nested attributes within the [`backends`] variable (https://github.com/terraform-google-modules/terraform-google-lb-http/blob/cb15ed7391f1bbcc4fdb6d55ee5703ca0d47447a/variables.tf#L81) is optional now. If supplied, the value for for the edge security policy will be set as such. Since [optional attributes](https://developer.hashicorp.com/terraform/language/expressions/type-constraints#optional-object-type-attributes)
is a version 1.3 feature, the configuration will fail if the pinned version is < 1.3.
