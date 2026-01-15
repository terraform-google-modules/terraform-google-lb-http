variable "regions" {
  description = "Regions to create backend groups (MIGs)"
  type        = map(string)
  default     = {
    "us-central1" = "us-central1"
    "us-east1"    = "us-east1"
  }
}

variable "vm_subnet_cidrs" {
  description = "VM subnet CIDRs per region"
  type        = map(string)
  default     = {
    "us-central1" = "10.10.0.0/24"
    "us-east1"    = "10.20.0.0/24"
  }
}

variable "region_to_zone" {
  description = "Region -> zone mapping for MIGs"
  type        = map(string)
  default     = {
    "us-central1" = "us-central1-a"
    "us-east1"    = "us-east1-b"
  }
}

variable "instance_image" {
  description = "Image for backend instances"
  type        = string
  default     = "projects/debian-cloud/global/images/family/debian-11"
}

variable "instance_machine_type" {
  description = "Machine type for backend instances"
  type        = string
  default     = "e2-medium"
}

variable "target_size" {
  description = "Number of VMs per MIG"
  type        = number
  default     = 2
}

variable "hostname" {
  description = "The domain name (hostname) for the Global Load Balancer"
  type        = string
  default     = "global.example.com"
}

variable "enable_dns_records" {
  description = "Whether to create DNS zone and records"
  type        = bool
  default     = true
}

variable "create_public_zone" {
  description = "Whether to create a new public managed zone in Cloud DNS"
  type        = bool
  default     = true
}

variable "public_zone_name" {
  description = "Name of an existing public zone (used if create_public_zone=false)"
  type        = string
  default     = "public-example-zone"
}
