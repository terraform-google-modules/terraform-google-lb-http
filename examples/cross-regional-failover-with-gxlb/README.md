# Cross-Regional Failover with GXLB Example

This example demonstrates how to use the **terraform-google-lb-http** module (or a variant that supports GXLB) to set up a **Global HTTP Load Balancer** with **cross-regional failover** capabilities (GXLB). The idea is que tráfego enviado ao *Global Load Balancer* será roteado para backends regionais saudáveis, com failover automático entre regiões.

Este projeto assume que sua versão do módulo *terraform-google-lb-http* (ou fork com suporte GXLB) já suporta a lógica de failover global entre regiões.

---

## How it Works

- **Backend module(s)**: serão criados recursos de backend (ex: *google_compute_backend_service*, instâncias, MIGs, health checks) em múltiplas regiões conforme definido nas variáveis.  
- **Frontend / Global module**: cria os recursos do balanceador global — endereço IP global, regras de encaminhamento globais (*global forwarding rules*), proxy HTTP/HTTPS, URL map com lógica de failover entre regiões (prioridades ou condições de health).  
- A lógica de failover global é configurada de modo que, se um backend em região A ficar indisponível, o tráfego será encaminhado para o backend em região B.

---

## Inputs

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
| Name                | Description                                                   | Type           | Default                         | Required |
|---------------------|---------------------------------------------------------------|----------------|----------------------------------|:--------:|
| project_id           | The GCP project ID                                             | `string`       | n/a                              | yes      |
| project              | Alias project ID (used in some resources)                      | `string`       | n/a                              | yes      |
| regions              | Map of regions where regional ALBs / backends will be created | `map(string)`  | see example default in variables | no       |
| vm_subnet_cidrs      | Map of VM subnet CIDRs per region                              | `map(string)`  | default map                     | no       |
| proxy_subnet_cidrs   | Map of proxy-only subnet CIDRs per region                     | `map(string)`  | default map                     | no       |
| default_region       | Default region used by the provider                           | `string`       | `"us-central1"`                 | no       |
| region_to_zone        | Map region → zone for MIGs                                     | `map(string)`  | default map                      | no       |
| instance_image        | Image to use for backend instances                             | `string`       | `"projects/debian-cloud/global/images/family/debian-11"` | no |
| instance_machine_type | Machine type for backend instances                             | `string`       | `"e2-medium"`                    | no       |
| target_size            | Number of VMs per managed instance group                      | `number`       | `2`                             | no       |
| regional_hostname      | DNS hostname used for certificates and DNS records            | `string`       | `"regional.example.com"`         | no       |
| enable_dns_records     | Whether to create DNS records                                 | `bool`        | `true`                           | no       |
| create_public_zone      | Whether to create a new public managed DNS zone               | `bool`        | `true`                           | no       |
| public_zone_name        | Name of existing public zone (if `create_public_zone = false`) | `string`     | `"public-example-zone"`          | no       |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
