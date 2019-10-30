# Global HTTP Example to GCE instances with NAT Gateway

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/GoogleCloudPlatform/terraform-google-lb-http&working_dir=examples/http-nat-gateway&page=shell&tutorial=README.md)

This example creates a global HTTP forwarding rule to an instance group without external IPs. The instances access the internet via a NAT gateway.

**Figure 1.** *diagram of Google Cloud resources*

![architecture diagram](https://raw.githubusercontent.com/GoogleCloudPlatform/terraform-google-lb-http/master/examples/http-nat-gateway/diagram.png)

## Change to the example directory

```
[[ `basename $PWD` != mig-nat-http-lb ]] && cd examples/mig-nat-http-lb
```

## Install Terraform

1. Install Terraform if it is not already installed (visit [terraform.io](https://terraform.io) for other distributions):

```
../terraform-install.sh
```

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

1. Wait for the load balancer to be provisioned:

```
./test.sh
```

2. Open the URL of the load balancer in your browser:

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
|------|-------------|:----:|:-----:|:-----:|
| network\_name |  | string | `"tf-lb-http-mig-nat"` | no |
| project |  | string | n/a | yes |
| region |  | string | `"us-west1"` | no |
| service\_account |  | object | `<map>` | no |
| zone |  | string | `"us-west1-b"` | no |

## Outputs

| Name | Description |
|------|-------------|
| backend\_services |  |
| load-balancer-ip |  |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
