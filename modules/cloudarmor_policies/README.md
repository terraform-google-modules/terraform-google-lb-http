# CloudArmor policies for Global HTTP Load Balancer
Terraform module for managing CloudArmor policies for attaching them to HTTP GCLBs.

## Usage
```HCL
module "gce-cloudarmor" {
  source            = "GoogleCloudPlatform/lb-http/google//modules/cloudarmor_policies"
  version           = "~> 6.2"

  project_id = var.project_id

  for_each = var.security_policies

  name = each.key
  description = "CloudArmor policy for ${each.key}"
  rules = each.value.rules
}
```

Please refer to the example.tfvars in examples/cloudarmor-policies folder for a reference example.

## Compatibility
This module is meant for use with Terraform 0.13+ and tested using Terraform 0.13+.
