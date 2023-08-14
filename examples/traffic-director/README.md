# External HTTPS Load Balancer with dynamic backends

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/GoogleCloudPlatform/terraform-google-lb-http&working_dir=examples/dynamic-backend&page=shell&tutorial=README.md)

This creates an external Envoy-based HTTPS Load Balancer using dynamic
backends suitable for integrating with a Google Kubernetes Engine cluster
running [gke-autoneg-controller](https://github.com/GoogleCloudPlatform/gke-autoneg-controller).
The load balancer will not route traffic to any backend service or bucket;
instead, it expects that an external user or service will register backends
(such as Network Endpoint Groups) accordingly to serve traffic. The example
will attempt to provision a Google-managed TLS certificate for the domain
"example.com" by default and use `/api/health` as a health check endpoint.

## Change to the example directory

```
[[ `basename $PWD` != https-gke ]] && cd examples/dynamic-backend
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

3. Create the dynamic backend load balancer.

```
(
    cd dynamic-backend/
    terraform init
    terraform plan -out terraform.tfplan
    terraform apply terraform.tfplan
)
```

4. Deploy the `gke-autoneg-controller` into a GKE cluster and configure it according to the instructions. This will create a Network Endpoint Group for a service and bind it to this load balancer.


## Cleanup

1. Delete the load balancing resources created by terraform:

```
terraform destroy
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| network\_name | n/a | `string` | `"traffic-director-lb"` | no |
| project\_id | n/a | `string` | n/a | yes |

## Outputs

No outputs.

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
