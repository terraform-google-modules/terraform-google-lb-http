# Upgrading to v8.0

The v8.0 release contains backwards-incompatible changes.

### [Terraform](https://www.terraform.io/downloads.html) >= 1.3.0 is required as `cdn_policy` and its nested attributes and objects are made optional in the `backends` object
The [`cdn_policy`](https://github.com/terraform-google-modules/terraform-google-lb-http/blob/0f0bf4cf0edceeee631c4a8e5d0140d40ca65128/variables.tf#L134-L155) object attribute and its nested attributes within the [`backends`] variable (https://github.com/terraform-google-modules/terraform-google-lb-http/blob/0f0bf4cf0edceeee631c4a8e5d0140d40ca65128/variables.tf#L81) is optional now. If supplied, the value for for the CDN policy will be set as such. Since [optional attributes](https://developer.hashicorp.com/terraform/language/expressions/type-constraints#optional-object-type-attributes)
is a version 1.3 feature, the configuration will fail if the pinned version is < 1.3.
