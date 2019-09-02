output "load-balancer-ip" {
  value = module.gce-lb-http.external_ip
}
