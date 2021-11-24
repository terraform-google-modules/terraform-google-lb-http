variable "project" {
  description = "The ID of the project to create the bucket in."
  type        = string
}

variable "domain" {
  description = "Zone domain, must end with a period."
  type        = string
}