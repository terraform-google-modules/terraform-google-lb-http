# Multiple Certificate Example

This example shows how to use multiple certificates with the HTTPS Load Balancer module.

## Set up the environment

```
gcloud auth application-default login
export GOOGLE_PROJECT=$(gcloud config get-value project)
```

## Run Terraform

```
terraform init
terraform plan
terraform apply
```

Open URL of load balancer in browser:

```
EXTERNAL_IP=$(terraform output -module gce-lb-https | grep external_ip | cut -d = -f2 | xargs echo -n)
(until curl -k -sf -o /dev/null https://${EXTERNAL_IP}; do echo "Waiting for Load Balancer... "; sleep 5 ; done) && open https://${EXTERNAL_IP}
```

You should see the GCP logo and instance details from the group closest to your geographical region.

```
open https://${EXTERNAL_IP}/group1/
```

You should see the GCP logo and instance details from the group in us-west1.

```
open https://${EXTERNAL_IP}/group2/
```

You should see the GCP logo and instance details from the group in us-central1.

```
open https://${EXTERNAL_IP}/group3/
```

You should see the GCP logo and instance details from the group in us-east1.

## Cleanup

Remove all resources created by terraform:

```
terraform destroy
```
