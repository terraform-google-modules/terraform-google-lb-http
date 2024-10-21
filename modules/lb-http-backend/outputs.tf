output "backend_service_info" {
  description = "Host, path and backend service mapping"
  value = [
    for mapping in var.host_path_mappings : {
      host            = mapping.host
      path            = mapping.path
      backend_service = google_compute_backend_service.default.self_link
    }
  ]
}
