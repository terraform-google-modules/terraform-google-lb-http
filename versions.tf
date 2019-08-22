provider "google" {
  project = var.project
  version = "~> 2.7.0"
}

provider "google-beta" {
  project = var.project
  version = "~> 2.7.0"
}

terraform {
  required_version = ">= 0.12"
}
