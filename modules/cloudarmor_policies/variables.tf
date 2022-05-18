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

variable "security_policies" {
  type        = any
  default     = {}
  description = "Cloud Armor security policies. https://cloud.google.com/armor/quotas#quotas for quotas."
}

variable "rules" {
  type = any
}

variable "name" {
  type        = string
  description = "Cloud Armor security policy name."
}

variable "description" {
  type        = string
  description = "Policy description"
  default     = ""
}

variable "project_id" {
  type        = string
  description = "ProjectID where policy is created."
  default     = ""
}
