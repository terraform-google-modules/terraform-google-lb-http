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
for production use.

1. Initialize:

    ```
    terraform init
    ```

2. Deploy the load balancer:

    ```
    terraform apply -var=project_id=$PROJECT 
    ```

3. Upload the provided site files to the cloud storage bucket. Visit the output bucket url of the storage bucket.

    ```
    gsutil cp /index.html <your-storage-bucket>
    gsutil cp /404.html <your-storage-bucket>
    ```

4. It may take some time for the load balancer to provision. Once completed, you can visit the output IP address of the load balancer to view the site.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project\_id | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| load-balancer-ip | ip of the public site |
| bucket-name | name of the cloud storage bucket |
| bucket-url | url of the cloud storage bucket |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
​