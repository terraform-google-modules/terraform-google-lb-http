# HTTP-to-HTTPS Redirect Example

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/GoogleCloudPlatform/terraform-google-lb-http&working_dir=examples/https-redirect&page=shell&tutorial=README.md)

This example shows how to enable HTTPS redirection on Google external
HTTP(S) load balancers.

## Change to the example directory

```
[[ `basename $PWD` != https-redirect ]] && cd examples/https-redirect
```

## Install Terraform

1. Install Terraform if it is not already installed (visit [terraform.io](https://terraform.io) for other distributions):

## Set up the environment

1. Set the project, replace `YOUR_PROJECT` with your project ID:

```
PROJECT=YOUR_PROJECT
```

```
gcloud config set project ${PROJECT}
```

2. Configure the environment for Terraform:

```
[[ $CLOUD_SHELL ]] || gcloud auth application-default login
export GOOGLE_PROJECT=$(gcloud config get-value project)
```

## Run Terraform

```
terraform init
terraform apply
```

## Testing

1. Open URL of load balancer in browser:

```
echo http://$(terraform output load-balancer-ip)
```

> You should see the Google Cloud logo and instance details.

## Cleanup

1. Remove all resources created by Terraform:

```
terraform destroy
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| network\_name | n/a | `string` | `"tf-lb-https-redirect-nat"` | no |
| project | n/a | `string` | n/a | yes |
| region | n/a | `string` | `"us-east1"` | no |
| zone | n/a | `string` | `"us-east1-b"` | no |

## Outputs

| Name | Description |
|------|-------------|
| backend\_services | n/a |
| load-balancer-ip | n/a |
| load-balancer-ipv6 | The IPv6 address of the load-balancer, if enabled; else "undefined" |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
