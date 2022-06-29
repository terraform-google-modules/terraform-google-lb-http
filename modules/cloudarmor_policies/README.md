# CloudArmor policies for Global HTTP Load Balancer
Terraform module for managing CloudArmor policies for attaching them to HTTP GCLBs.

## Usage
```HCL
module "cloud_armor_security_policies" {
  source     = "../../modules/cloudarmor_policies"
  project_id = var.project_id

  name        = "tf-managed-policy-01"
  description = "CloudArmor policy"

  rules = [{
        action         = "deny(401)"
        type           = "CLOUD_ARMOR_EDGE"
        priority       = "2147483647"
        versioned_expr = "SRC_IPS_V1"
        config = [{
          src_ip_ranges = ["*"]
        }]
        description = "Deny by default policy."
        }]
}
```

## Compatibility
This module is meant for use with Terraform 0.13+ and tested using Terraform 0.13+.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| description | Policy description | `string` | `""` | no |
| name | Cloud Armor security policy name. | `string` | n/a | yes |
| project\_id | ProjectID where policy is created. | `string` | n/a | yes |
| rules | n/a | `any` | n/a | yes |
| security\_policies | Cloud Armor security policies. https://cloud.google.com/armor/quotas#quotas for quotas. | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| security\_policy\_id | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
