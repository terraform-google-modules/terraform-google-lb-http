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

/**************************************************************
See:
- For TF properties: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_security_policy
- For CloudArmor quotas: https://cloud.google.com/armor/quotas#quotas
**************************************************************/

resource "google_compute_security_policy" "cloud_armor_security_policy" {
  project = var.project_id

  name        = var.name
  description = var.description

  dynamic "rule" {
    for_each = var.rules
    content {
      action      = rule.value.action
      priority    = rule.value.priority
      description = rule.value.description
      match {
        versioned_expr = lookup(rule.value, "versioned_expr", null)
        dynamic "config" {
          for_each = lookup(rule.value, "config", [])
          content {
            src_ip_ranges = lookup(config.value, "src_ip_ranges", null)
          }
        }
        dynamic "expr" {
          for_each = lookup(rule.value, "expr", [])
          content {
            expression = lookup(expr.value, "expression", null)
          }
        }
      }
    }
  }
}
