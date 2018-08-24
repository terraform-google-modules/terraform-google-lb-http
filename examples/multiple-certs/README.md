# Multiple Certificate Example

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/GoogleCloudPlatform/terraform-google-lb-http&working_dir=examples/multiple-certs&page=shell&tutorial=README.md)

<a href="https://concourse-tf.gcp.solutions/teams/main/pipelines/tf-examples-lb-https-multi-cert" target="_blank">
<img src="https://concourse-tf.gcp.solutions/api/v1/teams/main/pipelines/tf-examples-lb-https-multi-cert/badge" /></a>

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