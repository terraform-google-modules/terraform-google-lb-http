# HTTPS load balancer with Serverless NEG backend example (Cloud Run)

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://wapfel/terraform-google-lb-http&working_dir=examples/static-website-with-domain-ssl&page=shell&tutorial=README.md)

This example creates at static website using a public Google Cloud Storage bucket containing basic html website files and exposes it behind a Cloud HTTPS load balancer and CDN accessible via a global IP. If you have your own domain and would like to use SSL, please see the [static-website-with-domain-ssl](https://github.com/wapfel/terraform-google-lb-http/tree/master/examples/static-website-with-domain-ssl) example.
​
You can tweak this example to enable other functionalities such as:
​
- configuring custom CDN caching policies
- serving static assets from multiple cloud storage buckets
- serving static and dynamic assets from backend buckets and backend services
​
## Change to the example directory

[[ `basename $PWD` != static-website-with-domain-ssl ]] && cd examples/static-website-with-domain-ssl

## Install Terraform

1. Install Terraform if it is not already installed (visit [terraform.io](https://terraform.io) for other distributions):

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
​
## Run on HTTP load balancer (unencrypted, not recommended for production)

This option provisions an HTTP forwarding rule (insecure) and is not recommended
for production use. It is provided since it provisions faster than the Option 2.

1. Initialize:

    ```
    terraform init
    ```

1. Deploy the load balancer, replace `example.com` with your domain name.

    ```
    terraform apply -var=project_id=$PROJECT \
        -var=ssl=false -var=domain=null
    ```

1. It may take some time for the load balancer to provision. Visit the output
   IP address of the load balancer.

## Option 2: Run on HTTPS load balancer (with HTTP-to-HTTPS redirect)

This options creates a Google-managed SSL certificate for your domain name,
sets it up on HTTPS forwarding rule and creates a HTTP forwarding rule to
redirect HTTP traffic to HTTPS.

1. Make sure you have a **domain name**. This is required since we provision a
   Google-managed SSL certificate specifically for this domain name.

1. Initialize:

    ```
    terraform init
    ```

1. Deploy the load balancer, replace `example.com` with your domain name.

    ```
    terraform apply -var=project_id=$PROJECT \
        -var=domain=example.com
    ```

1. After the deployment completes it outputs the IP address of the load balancer.
   Update DNS records for your domain to point to this IP address.

1. It may take around half an hour for the SSL certificate to be provisioned
   and the application to start serving traffic.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| domain | Domain name to run the load balancer on. Used if `ssl` is `true`. | `string` | n/a | yes |
| lb-name | Name for load balancer and associated resources | `string` | `"run-lb"` | no |
| project\_id | n/a | `string` | n/a | yes |
| region | Location for load balancer and Cloud Run resources | `string` | `"us-central1"` | no |
| ssl | Run load balancer on HTTPS and provision managed certificate with provided `domain`. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| load-balancer-ip | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
​