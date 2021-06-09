# Global HTTP Example to GCE instances with NAT Gateway

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/GoogleCloudPlatform/terraform-google-lb-http&working_dir=examples/http-nat-gateway&page=shell&tutorial=README.md)

This example creates a global HTTP forwarding rule to an instance group without external IPs. The instances access the internet via a NAT gateway.

**Figure 1.** *diagram of Google Cloud resources*

![architecture diagram](./diagram.png)

## Change to the example directory

```
[[ `basename $PWD` != mig-nat-http-lb ]] && cd examples/mig-nat-http-lb
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

1. Open the URL of the load balancer in your browser:

```
echo http://$(terraform output load-balancer-ip)
```

You should see the instance details from `group1`.

## Cleanup

1. Remove all resources created by terraform:

```
terraform destroy
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| network\_name | n/a | `string` | `"tf-lb-http-mig-nat"` | no |
| project | n/a | `string` | n/a | yes |
| region | n/a | `string` | `"us-west1"` | no |
| zone | n/a | `string` | `"us-west1-b"` | no |

## Outputs

| Name | Description |
|------|-------------|
| backend\_services | n/a |
| load-balancer-ip | n/a |
| load-balancer-ipv6 | The IPv6 address of the load-balancer, if enabled; else "undefined" |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
