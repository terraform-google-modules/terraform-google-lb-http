# HTTP Internal Cross-Regional Load Balancer Example

This example creates a simple application with below components.

* *Frontend Service*: Two cloud-run services to send request to internal cross-regional load balancers. The cloud-run service uses VPC access connector to send the request to the internal load balancer.
* *Internal Load Balancer*: An internal cross-regional load balancer to distribute traffic to internal cloud run services.
* *Backend Service*: Two cloud-run services to run the actual application code. These can be accessed within internal traffic. The internal Application Load Balancer is considered internal traffic.


The `google_compute_backend_service` and its dependencies are created as part of `backend` module.
The forwarding rules and its dependecies are created as part of `frontend` module.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project\_id | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| external\_cloudrun\_uris | List of URIs for the frontend Cloud Run services |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
