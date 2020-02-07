# HTTPS load balancer with existing GKE cluster example

This example shows how Terraform can be combined with the [Autoneg controller](https://github.com/GoogleCloudPlatform/gke-autoneg-controller).
Using this controller allows you to connect GKE services to load balancers managed outside of GKE, including multi-regional load balancers.

## Usage
1. Clone this repo and open the example directory.

        git clone https://github.com/terraform-google-modules/terraform-google-lb-http
        cd terraform-google-lb-http/examples/gke-autoneg

1. Set a few config values:

        # The project hosting our GKE cluster
        export TF_VAR_project="my-project"
        # The name of your network host project (can be same)
        export TF_VAR_network_project="my-network-host-project"
        # The name of your network
        export TF_VAR_network_name="my-network
        # Instance tags applied to your GKE nodes
        export TF_VAR_firewall_target_tags='["gke-cluster-node"]'

1. Create a cluster with Workload Identity enabled.
    This can be done using the [Terraform GKE module](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine).

1. Once you have a cluster, fetch credentials for accessing the cluster.

        gcloud container clusters get-credentials $CLUSTER_NAME \
            --zone us-central1-a \
            --project $TF_VAR_project

1. Use Terraform to create a namespace in the cluster and the HTTP load balancer.

        terraform init
        terraform apply

4. Install the autoneg controller into the `autoneg-system` namespace:

        kubectl apply -f manifests/autoneg.yaml

5. Deploy a sample [Nginx service](./manifests/nginx.yaml):

        kubectl apply -f manifests/nginx.yaml

6. Access the nginx service through the load balancer. Note that it may take some time before the service is registered fully.

        curl $(tf output endpoint)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| firewall\_target\_tags | Network tags to target for firewall rules, corresponding to your GKE nodes | list(string) | n/a | yes |
| network\_name | The name of the network hosting your GKE cluster | string | n/a | yes |
| network\_project | The project hosting your network | string | n/a | yes |
| project\_id | The project hosting your GKE cluster | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| backend-name | Backend service name to use in autoneg annotations |
| endpoint | External IP to access load balancer |
| lb | Full load balancer configuration |
| project | Project ID configured for resources |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Troubleshooting

If you see errors from the load balancer, you should first confirm that nginx is properly serving traffic by setting up local port-forwarding:

```
kubectl port-forward service/hello-neg 7000:80
curl localhost:7000
```

If nginx is serving properly, you should check the autoneg controller for errors:
```
kubectl logs -l control-plane=controller-manager -c manager
```
