# HTTPS load balancer with Serverless NEG backend example (Cloud Run)

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/GoogleCloudPlatform/terraform-google-lb-http&working_dir=examples/cloudrun&page=shell&tutorial=README.md)

This example deploys a Cloud Run application, creates a Serverless Network
Endpoint Group (NEG) and exposes it behind a Cloud HTTPS load balancer with
HTTP-to-HTTPS redirection.

You can tweak this example to enable other functionalities such as:

- serving static assets from Cloud CDN
- enabling a security profile via Cloud Armor
- run global endpoints by deploying Cloud Run service to multiple regions.

## Change to the example directory

```
[[ `basename $PWD` != cloudrun ]] && cd examples/cloudrun
```

## Install Terraform

1. Install Terraform if it is not already installed (visit
   [terraform.io](https://terraform.io) for other distributions):

## Set up the environment

1. Set the project, replace `YOUR_PROJECT` with your project ID:-

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

## Option 1: Run on HTTPS load balancer (with HTTP-to-HTTPS redirect)

This options creates a Google-managed SSL certificate for your domain name,
sets it up on HTTPS forwarding rule and creates a HTTP forwarding rule to
redirect HTTP traffic to HTTPS.

1. Make sure you have a **domain name**. This is required since we provision a
   Google-managed SSL certificate specifically for this domain name.

1. Initialize:

    ```
    terraform init
    ```

2. Deploy the load balancer, replace `example.com` with your domain name.

    ```
    terraform apply -var=project=$PROJECT \
        -var=ssl=true \
        -var=domain=example.com
    ```

3. After the deployment completes it outputs the IP address of the load balancer.
   Update DNS records for your domain to point to this IP address.

4. It may take around half an hour for the SSL certificate to be provisioned
   and the application to start serving traffic.

## Option 2: Run on HTTP load balancer (unencrypted)

This option provisions an HTTP forwarding rule (insecure) and is not recommended
for production use.

1. Initialize:

    ```
    terraform init
    ```

2. Deploy the load balancer, replace `example.com` with your domain name.

    ```
    terraform apply -var=project=$PROJECT \
        -var=ssl=false
    ```

3. It may take some time for the load balancer to provision. Visit the output
   IP address of the load balancer.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| domain | Domain name to run the load balancer on. Used if `ssl` is `true`. | string | `""` | no |
| lb-name | Name for load balancer and associated resources | string | `"run-lb"` | no |
| project |  | string | n/a | yes |
| region | Location for load balancer and Cloud Run resources | string | `"us-central1"` | no |
| ssl | Run load balancer on HTTPS and provision managed certificate with provided `domain`. | bool | `"true"` | no |

## Outputs

| Name | Description |
|------|-------------|
| load-balancer-ip |  |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
