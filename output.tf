# Stack output configuration

output "app_url" {
  description = "Application URL : "
  value = (var.create_fqdn ? "https://${local.domain_name}" : oci_load_balancer.flexible_loadbalancer.ip_address_details[0].ip_address)
}
