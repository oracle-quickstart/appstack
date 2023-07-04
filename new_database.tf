#create new database 
resource "oci_database_autonomous_database" "database" {
  depends_on = [
    oci_core_subnet.db_oci_core_subnet,
    oci_core_network_security_group.db_nsg
  ]
  admin_password = var.autonomous_database_admin_password
  compartment_id = var.compartment_id
  db_name = var.autonomous_database_display_name
  display_name = var.autonomous_database_display_name
  data_storage_size_in_tbs = var.data_storage_size_in_tbs
  cpu_core_count = var.ocpu_count 
  db_version = var.db_version
  is_mtls_connection_required = (local.use-image ? false : true)
  license_model = var.db_license_model
  # Set subnet and nsg for private endpoint connection with app
  subnet_id = local.db_subnet_id
  nsg_ids = [oci_core_network_security_group.db_nsg[0].id]
  count = var.use_existing_database ? 0 : 1
}
