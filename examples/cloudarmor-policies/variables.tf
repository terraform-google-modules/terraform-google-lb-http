variable "security_policies" {
    type = any
    description = "CloudArmor security policies"
    default = {}
}

variable "project_id" {
  type = string
  description = "Project where the policies are created."
}

variable "region" {
    default = "us-central1"
    type = string
    description = "Resources region"
  
}