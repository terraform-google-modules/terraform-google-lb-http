/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# Create a namespace for autoneg
resource "kubernetes_namespace" "autoneg" {
  metadata {
    labels = {
      control-plane = "controller-manager"
    }

    name = "autoneg-system"
  }
}

# Connect the Kubernetes service account with GCP
module "workload_identity" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "~> 9.0"

  project_id          = var.project_id
  name                = "autoneg-system"
  k8s_sa_name         = "default"
  namespace           = "${kubernetes_namespace.autoneg.metadata.0.name}"
  use_existing_k8s_sa = true
}

# Create a role for autoneg
resource "google_project_iam_custom_role" "autoneg" {
  project     = var.project_id
  role_id     = "autoneg"
  title       = "autoneg controller"
  description = "Allow GKE autoneg controller to update load balancers"
  permissions = [
    "compute.backendServices.get",
    "compute.backendServices.update",
    "compute.networkEndpointGroups.use",
    "compute.healthChecks.useReadOnly"
  ]
}

# Give the GCP SA the new autoneg role
resource "google_project_iam_member" "autoneg" {
  project = var.project_id
  role    = "projects/${var.project}/roles/${google_project_iam_custom_role.autoneg.role_id}"
  member  = module.workload_identity.gcp_service_account_fqn
}
