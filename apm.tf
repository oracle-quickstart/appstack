# this file configures the domain for Application Performance Monitoring

resource "oci_apm_apm_domain" "app_apm_domain" {
  compartment_id = var.compartment_id
  display_name = "${var.application_name}-apm-domain"
  is_free_tier = var.is_free_tier
}

data "oci_apm_data_keys" "private_key" {
    apm_domain_id = oci_apm_apm_domain.app_apm_domain.id
    data_key_type = "PRIVATE"
}