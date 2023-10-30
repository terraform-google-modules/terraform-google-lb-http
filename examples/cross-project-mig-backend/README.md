# HTTP Load Balancer Example

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/GoogleCloudPlatform/terraform-google-lb-http&working_dir=examples/cross-project-mig-backend&page=shell&tutorial=README.md)

This example creates a global HTTP forwarding rule in host project to forward traffic to instance groups in service project.

## Change to the example directory

```
[[ `basename $PWD` != cross-project-mig-backend ]] && cd examples/cross-project-mig-backend
```

## Install Terraform

1. Install Terraform if it is not already installed (visit [terraform.io](https://terraform.io) for other distributions):

## Set up the environment


1. Configure the environment for Terraform:

```
[[ $CLOUD_SHELL ]] || gcloud auth application-default login
```

## Run Terraform

```
terraform init
terraform apply
```

## Test load balancing

1. Open the URL of the load balancer in your browser:

```
echo http://$(terraform output load-balancer-ip)
```

## Cleanup

1. Remove all resources created by terraform:

```
terraform destroy
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| network\_name | n/a | `string` | `"multi-mig-cross-project-mig"` | no |
| project\_id | ID for the Shared VPC host project | `any` | n/a | yes |
| project\_id\_1 | ID for the Shared VPC service project where instances will be deployed | `any` | n/a | yes |
| region | n/a | `string` | `"us-central1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| load-balancer-ip | The external IP assigned to the load balancer. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
