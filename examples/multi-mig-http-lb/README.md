# HTTP Load Balancer Example

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/GoogleCloudPlatform/terraform-google-lb-http&working_dir=examples/basic&page=shell&tutorial=README.md)

This example creates a global HTTP forwarding rule to forward traffic to instance groups in the us-west1 and us-east1 regions.

**Figure 1.** *diagram of Google Cloud resources*

![architecture diagram](https://raw.githubusercontent.com/GoogleCloudPlatform/terraform-google-lb-http/master/examples/multi-mig-http-lb/diagram.png)

## Change to the example directory

```
[[ `basename $PWD` != multi-mig-http-lb ]] && cd examples/multi-mig-http-lb
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

You should see the instance details from the region closest to you.

## Test balancing to other region

Resize the instance group of your closest region to cause traffic to flow to the other group.

1. If you are getting traffic from `group1` (us-west1), scale group 1 to 0 instances:

```
TF_VAR_group1_size=0 terraform apply
```

2. Otherwise scale group 2 (us-east1) to 0 instances:

```
TF_VAR_group2_size=0 terraform apply
```

3. Open the external IP again and verify you see traffic from the other group:

```
echo http://$(terraform output load-balancer-ip)
```

> It may take several minutes for the global load balancer to be created and the backends to register.

## Cleanup

1. Remove all resources created by terraform:

```
terraform destroy
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| group1\_region |  | string | `"us-west1"` | no |
| group2\_region |  | string | `"us-east1"` | no |
| network\_prefix |  | string | `"multi-mig-lb-http"` | no |
| project |  | string | n/a | yes |
| service\_account |  | object | `<map>` | no |
| target\_size |  | number | `"2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| load-balancer-ip |  |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
