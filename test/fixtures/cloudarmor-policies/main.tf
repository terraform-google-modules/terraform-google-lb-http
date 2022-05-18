/**
 * Copyright 2022 Google LLC
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

module "example" {
  source     = "../../../examples/cloudarmor-policies"
  project_id = var.project_id


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
    }
  }
}
