# HTTPS load balancer with Cloud Storage Backend example (Including DNS & SSL)

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/wapfel/terraform-google-lb-http&working_dir=examples/static-website-with-domain-ssl&page=shell&tutorial=README.md)

This example creates a static website using a public Google Cloud Storage bucket containing basic html website files and exposes it behind a Cloud HTTPS load balancer and Cloud CDN with HTTP-to-HTTPS redirection. Additionally, this module creates a public DNS zone for a provided domain and corresponding DNS records, and it creates a Google-managed certificate for SSL.

If you do not have your own domain and would like to test the static website fuctionality, please see the [static-website-with-no-domain](https://github.com/wapfel/terraform-google-lb-http/tree/master/examples/static-website-with-no-domain) example.
​
You can tweak this example to enable other functionalities such as:
​
- configuring custom CDN caching policies
- securely serving static assets from multiple cloud storage buckets
- securely serving static and dynamic assets from backend buckets and backend services
​
## Change to the example directory

```
[[ `basename $PWD` != static-website-with-domain-ssl ]] && cd examples/static-website-with-domain-ssl
```

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
## Run on HTTP load balancer using SSL and an HTTP-to-HTTPs Redirect (secure)

This option provisions an ssl certificate and a redirect from http to https traffic for your website content.

1. Initialize:

    ```
    terraform init
    ```

2. Deploy the load balancer (your must provide your domain below to configure Cloud DNS and your SSL certificate):

    ```
    terraform apply -var=project=$PROJECT \
        -var=domain=<yourdomain.com>

    ```

3. Upload the provided site files to the cloud storage bucket. Visit the output bucket url of the storage bucket.

    ```
    gsutil cp index.html <your-storage-bucket>
    gsutil cp 404.html <your-storage-bucket>
    ```

5. Update the name servers in your domain registry to point to the Cloud DNS zone's name servers provided in the output.

5. It may take some time for the load balancer and your SSL certificate to fully provision. Once completed, you can visit your site at https://yourdomain.com and https://www.yourdomain.com. http will redirect to https.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project | n/a | `string` | n/a | yes |
| domain | your domain name (ex. yourdomain.com)| `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| name-servers | the list of name servers from Cloud DNS to add to your domain registry |
| load-balancer-ip | ip of the public site |
| bucket-name | name of the cloud storage bucket |
| bucket-url | url of the cloud storage bucket |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
​