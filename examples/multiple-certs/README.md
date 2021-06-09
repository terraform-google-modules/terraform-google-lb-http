# Multiple Certificate Example

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/GoogleCloudPlatform/terraform-google-lb-http&working_dir=examples/multiple-certs&page=shell&tutorial=README.md)

This example shows how to use multiple certificates with the HTTPS Load Balancer module.

## Change to the example directory

```
[[ `basename $PWD` != multiple-certs ]] && cd examples/multiple-certs
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

2. Open URL of load balancer in browser:

```
echo http://$(terraform output load-balancer-ip)
```

> You should see the GCP logo and instance details from the group closest to your geographical region.

3. Open URL to route mapped to us-west1 instance group:

```
echo https://${EXTERNAL_IP}/group1/
```

> You should see the GCP logo and instance details from the group in us-west1.

4. Open URL to route mapped to us-central1 instance group:

```
echo https://${EXTERNAL_IP}/group2/
```

> You should see the GCP logo and instance details from the group in us-central1.

5. Open URL to route mapped to us-east1 instance group:

```
echo https://${EXTERNAL_IP}/group3/
```

> You should see the GCP logo and instance details from the group in us-east1.

## Cleanup

1. Remove all resources created by terraform:

```
terraform destroy
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| group1\_region | n/a | `string` | `"us-west1"` | no |
| group1\_zone | n/a | `string` | `"us-west1-a"` | no |
| group2\_region | n/a | `string` | `"us-central1"` | no |
| group2\_zone | n/a | `string` | `"us-central1-f"` | no |
| group3\_region | n/a | `string` | `"us-east1"` | no |
| group3\_zone | n/a | `string` | `"us-east1-b"` | no |
| network\_name | n/a | `string` | `"tf-lb-https-multi-cert"` | no |
| project | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| asset-url | n/a |
| asset-url-ipv6 | The asset url over IPv6 address of the load-balancer, if enabled; else "undefined" |
| group1\_region | n/a |
| group2\_region | n/a |
| group3\_region | n/a |
| load-balancer-ip | n/a |
| load-balancer-ipv6 | The IPv6 address of the load-balancer, if enabled; else "undefined" |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
