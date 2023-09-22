# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

## .NET specific variables and locals
locals {
  # Get output folder path and dll name
  output_path = "${dirname(var.artifact_location)}/"
  dll_name = basename(var.artifact_location)
  # path to the wallet
  wallet_path = "/opt/dotnetapp/wallet"

  driver_connection_url = (
    var.use_existing_database 
      ? "${replace(data.oci_database_autonomous_database.autonomous_database.connection_strings[0].profiles[local.conn_url_index].value, "description= ", "description=")}"
      : "${replace(oci_database_autonomous_database.database[0].connection_strings[0].profiles[local.conn_url_index].value, "description= ", "description=")}"
  )
  # Connection URL environment variable
  connection_url_env = "ENV ${var.connection_url_env}=${local.escaped_connection_url}" 
}