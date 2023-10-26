# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Stack output configuration

output "app_url" {
  description = "Application URL : "
  value = (var.create_fqdn ? "https://${local.domain_name}" : "http://${oci_load_balancer_load_balancer.flexible_loadbalancer.ip_address_details[0].ip_address}")
}
