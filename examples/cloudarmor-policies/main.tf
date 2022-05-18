locals {
  security_policies = {
  "tf-managed-policy-01" = {
    rules = [{
      action         = "allow" #Allow by default policy
      type           = "CLOUD_ARMOR_EDGE"
      priority       = "2147483647" #Default rule priority.
      versioned_expr = "SRC_IPS_V1"
      config = [{
        src_ip_ranges = ["*"]
      }]
      description = "Default rule, higher priority overrides it"
      },
      {
        action   = "deny(404)" 
        priority = "1000"
        expr = [{
          expression = "evaluatePreconfiguredExpr('sqli-stable') || evaluatePreconfiguredExpr('xss-stable') || evaluatePreconfiguredExpr('php-stable') || evaluatePreconfiguredExpr('cve-canary')"
        }]
        description = "Protection for Google Cloud Preconfigured expressions."
    }]
  },
    "tf-managed-policy-02" = {
      rules = [{
        action         = "deny(404)" #Deny by default policy
        type = "CLOUD_ARMOR_EDGE"
        priority       = "2147483647" 
        versioned_expr = "SRC_IPS_V1"
        config = [{
            src_ip_ranges  = ["*"]
        }]
        description    = "Default rule, higher priority overrides it."
        },
        {
          action      = "allow" 
          priority    = "1000"
        versioned_expr = "SRC_IPS_V1"
        config = [{
            src_ip_ranges  = ["1.2.3.0/24", "5.6.7.8"]
        }]
          description = "Allow traffic only from specific sources."
        }]
    },
}
}

module "cloud_armor_security_policies" {
    source = "../../modules/cloudarmor_policies"
    project_id = var.project_id

    for_each = local.security_policies

    name = each.key
    description = "CloudArmor policy for ${each.key}"
    
    rules = each.value.rules
}

provider "google" {
  project = var.project_id
}

provider "google-beta" {
  project = var.project_id
}

module "lb-http" {
  
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "6.2.0"
  name    = "cloud-armor-test-gclb"
  project = var.project_id

  ssl                             = false
  https_redirect                  = false

  backends = {
    default = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.serverless_neg.id
        }
      ]
      enable_cdn              = false
      security_policy         = "projects/${var.project_id}/global/securityPolicies/tf-managed-policy-01"
      custom_request_headers  = null
      custom_response_headers = null

      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }
      log_config = {
        enable      = false
        sample_rate = null
      }
    }
  }
  depends_on = [
    module.cloud_armor_security_policies
  ]
}

resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  provider              = google-beta
  name                  = "serverless-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_service.default.name
  }
}

resource "google_cloud_run_service" "default" {
  name     = "example"
  location = var.region
  project  = var.project_id

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
      }
    }
  }
}

resource "google_cloud_run_service_iam_member" "public-access" {
  location = google_cloud_run_service.default.location
  project  = google_cloud_run_service.default.project
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
