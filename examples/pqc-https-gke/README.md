# HTTPS load balancer with GKE cluster and Post-Quantum Cryptography (PQC) example

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/terraform-google-modules/terraform-google-lb-http&working_dir=examples/pqc-https-gke&page=shell&tutorial=README.md)

This example creates an HTTPS load balancer that forwards traffic to a GKE cluster with **Post-Quantum Cryptography (PQC)** enabled via a custom SSL Policy.

The infrastructure includes:
- A Global HTTPS Load Balancer.
- A `google_compute_ssl_policy` with `post_quantum_key_exchange` enabled.
- A URL map routing traffic to GKE NodePorts.
- A Cloud Storage backend for static assets (`/assets`).
- Self-signed certificates generated via the TLS provider.

**Note:** The `post_quantum_key_exchange` feature requires a supported Google Cloud Region and Provider version.

## Architecture

**Figure 1.** *diagram of Google Cloud resources*

![architecture diagram](https://raw.githubusercontent.com/terraform-google-modules/terraform-google-lb-http/master/examples/pqc-https-gke/diagram.png)

## Change to the example directory

```
[[ `basename $PWD` != pqc-https-gke ]] && cd examples/pqc-https-gke
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

## Option 1 - Example using new cluster

1. Deploy a new GKE cluster with a named node port:

```
(
    cd gke-node-port/
    terraform init
    terraform plan -out terraform.tfplan
    terraform apply terraform.tfplan
)
```

2. Export the instance group URI, node tag, network name and Project ID as Terraform environment variables:

```
export TF_VAR_backend=$(terraform output -raw -state gke-node-port/terraform.tfstate instance_group)
export TF_VAR_target_tags=$(terraform output -raw -state gke-node-port/terraform.tfstate node_tag)
export TF_VAR_network_name=$(terraform output -raw -state gke-node-port/terraform.tfstate network_name)
export TF_VAR_project=$GOOGLE_PROJECT
```

3. Run Terraform to create the load balancer:

```
terraform init
terraform apply
```

## Post-Quantum Cryptography Validation

After deployment, you can verify that the SSL Policy has PQC enabled:

```bash
SSL_POLICY_NAME=$(terraform output -raw ssl_policy_name)
gcloud compute ssl-policies describe ${SSL_POLICY_NAME} --format="get(postQuantumKeyExchange)"
```

Expected output: `ENABLED`

## Cleanup

1. Delete the load balancing resources created by terraform:

```
terraform destroy
```

2. (Option 1 only) Delete the GKE cluster:

```
cd gke-node-port/
terraform destroy
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| backend | Map backend indices to list of backend maps. | `any` | n/a | yes |
| name | n/a | `string` | `"tf-lb-https-gke"` | no |
| network\_name | n/a | `string` | `"default"` | no |
| project | n/a | `string` | n/a | yes |
| service\_port | n/a | `string` | `"30000"` | no |
| service\_port\_name | n/a | `string` | `"http"` | no |
| target\_tags | n/a | `string` | `"tf-lb-https-gke"` | no |

## Outputs

| Name | Description |
|------|-------------|
| load_balancer_ip | n/a |
| load_balancer_ipv6 | The IPv6 address of the load-balancer, if enabled; else "undefined" |
| project\_id | The project ID |
| ssl\_policy\_name | The name of the SSL policy with PQC enabled |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
