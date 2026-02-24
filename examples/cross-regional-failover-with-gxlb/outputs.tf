output "global_lb_ip" {
  description = "The public IP address of the Global Load Balancer."
  value       = google_compute_global_address.global_addr.address
}

output "hostname" {
  description = "The domain name (hostname) configured for the Global Load Balancer."
  value       = var.hostname
}
