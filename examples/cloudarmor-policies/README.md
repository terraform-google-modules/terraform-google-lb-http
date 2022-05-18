<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project\_id | Project where the policies are created. | `string` | n/a | yes |
| region | Resources region | `string` | `"us-central1"` | no |
| security\_policies | CloudArmor security policies | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| load-balancer-ip | n/a |
| security\_policy\_id | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->