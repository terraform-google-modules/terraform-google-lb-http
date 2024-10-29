# HTTP Load Balancer Example - Separate modules for creating HTTP load balancer frontend and backend resources

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/GoogleCloudPlatform/terraform-google-lb-http&working_dir=examples/lb-http-separate-frontend-and-backend&page=shell&tutorial=README.md)

This example creates a global HTTP forwarding rule to forward traffic to instance groups in the us-west1 and us-east1 regions. The `google_compute_backend_service` and its dependencies are created as part of `backend` module.
The forwarding rules and its dependecies are created as part of `frontend` modules.

## Change to the example directory

```
[[ `basename $PWD` != lb-http-separate-frontend-and-backend ]] && cd examples/lb-http-separate-frontend-and-backend
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

## Test load balancing

1. Open the URL of the load balancer in your browser:

```
echo http://$(terraform output load-balancer-ip)
```

You should see the instance details from the region closest to you.

## Test forwarding to the other region

1. Change the size of the instance group that’s currently serving requests to zero, so that traffic is forwarded to the group in the other region.

   For example, if requests are being served from group1 (us-west1), resize group1 to zero. You can do this using the [`gcloud` CLI](https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/resize) or the [web console](https://cloud.google.com/compute/docs/instance-groups/creating-groups-of-managed-instances#resize_managed_group).

   ```
   gcloud compute instance-groups managed resize lb-http-separate-frontend-and-backend-group1-mig --size=0 --region=us-west1
   ```
   It may take a few minutes for the instance group to be resized.

   **Note**: This change will cause your infrastructure to _drift_ from the Terraform state. You can run `terraform apply` at any time to update the infrastructure to match the Terraform state.

2. Open the external load-balancer IP address again, and verify that you see responses from the instance group in the other region.

  ```
  echo http://$(terraform output load-balancer-ip)| sed 's/"//g'
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
| project\_id | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| load-balancer-ip | n/a |
| load-balancer-ipv6 | The IPv6 address of the load-balancer, if enabled; else "undefined" |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
