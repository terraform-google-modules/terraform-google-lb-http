# Shared VPC Example

This example shows how to use this module in a Shared VPC setup. In a service project, it creates a global HTTP forwarding rule to forward traffic to an instance group. Meanwhile it ensures the host project has firewall rules in place to allow the health check ingress.

## Usage

### Configure the module

To connect your load balancer to a Shared VPC, you need to edit some inputs to match your environment. Copy `example.tfvars` into `terraform.tfvars` and update the [inputs](#inputs) to specify your desired Shared VPC network.

```
cp example.tfvars terraform.tfvars
vi terraform.tfvars
```

### Authenticate Terraform

```
gcloud auth application-default login
```

### Run Terraform

```
terraform init
terraform plan
terraform apply
```

Open URL of load balancer in browser:

```
EXTERNAL_IP=$(terraform output external_ip)
(until curl -sf -o /dev/null $EXTERNAL_IP; do echo "Waiting for Load Balancer... "; sleep 5; done) && open http://$EXTERNAL_IP
```

> Wait for all instance to become healthy per output of:

```
gcloud compute backend-services get-health group-http-lb-backend-0 --global --project=$(terraform output service_project)
```

### Cleanup

Remove all resources created by terraform:

```
terraform destroy
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| group_size | Size of managed instance group to create | string | `2` | no |
| host_project | ID for the Shared VPC host project | string | - | yes |
| network | ID of network to launch instances on | string | - | yes |
| region |  | string | `us-central1` | no |
| service_account_email | The email of the service account for the MIG instance template. | string | `default` | no |
| service_project | ID for the Shared VPC service project where instances will be deployed | string | - | yes |
| subnetwork | ID of subnetwork to launch instances on | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| external_ip | The external IP assigned to the load balancer. |
| service_project | The service project the load balancer is in. |
