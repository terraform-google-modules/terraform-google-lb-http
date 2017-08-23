variable project {
  description = "The project to deploy to, if not set the default provider project is used."
  default     = ""
}

variable region {
  description = "Region for cloud resources"
  default     = "us-central1"
}

variable network {
  description = "Name of the network to create resources in"
  default     = "default"
}

variable name {
  description = "Name for the forwarding rule and prefix for supporting resources"
}

variable target_tags {
  description = "List of target tags for health check firewall rule."
  type        = "list"
}

variable backends {
  description = "Map backend indices to list of backend maps."
  type        = "map"
}

variable backend_params {
  description = "Comma-separated encoded list of parameters in order: health check path, service port name, service port, backend timeout seconds"
  type        = "list"
}

variable create_url_map {
  description = "Set to `false` if url_map variable is provided."
  default     = true
}

variable url_map {
  description = "The url_map resource to use. Default is to send all traffic to first backend."
  default     = ""
}

variable ssl {
  description = "Set to `true` to enable SSL support, requires variables `private_key` and `certificate`."
  default     = false
}

variable private_key {
  description = "Content of the private SSL key. Required if ssl is `true`."
  default     = ""
}

variable certificate {
  description = "Content of the SSL certificate. Required if ssl is `true`."
  default     = ""
}
