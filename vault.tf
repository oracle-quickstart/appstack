# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

resource "oci_kms_vault" "app_vault" {
  compartment_id = var.compartment_id
  display_name = var.new_vault_display_name
  vault_type = "DEFAULT"
  count = var.use_existing_vault ? 0 : 1
}

resource "oci_kms_key" "app_key" {
  compartment_id = var.compartment_id
  display_name = "${var.new_vault_display_name}-key"
  key_shape {
      algorithm = "AES"
      length = 256
  }
  management_endpoint = oci_kms_vault.app_vault[0].management_endpoint 
  count = var.use_existing_vault ? 0 : 1
}


# Secret containing the db user's password
resource "oci_vault_secret" "db_user_password" {
  depends_on = [ 
    oci_kms_vault.app_vault,
    oci_kms_key.app_key
  ]
  #Required
  compartment_id = var.use_existing_vault ? var.vault_compartment_id : var.compartment_id
  secret_content {
      #Required
      content_type = "BASE64"

      #Optional
      content = base64encode(local.password)
      name = "db_user_password_${var.application_name}_${formatdate("MMDDhhmm", timestamp())}"
  }
  secret_name = "db_user_password_${var.application_name}_${formatdate("MMDDhhmm", timestamp())}"
  vault_id = var.use_existing_vault ? var.vault_id : oci_kms_vault.app_vault[0].id
  key_id = var.use_existing_vault ? var.key_id : oci_kms_key.app_key[0].id
}

# Secret containing the db wallet password
resource "oci_vault_secret" "db_wallet_password" {
  depends_on = [ 
    oci_kms_vault.app_vault,
    oci_kms_key.app_key,
    random_password.wallet_password
  ]
  #Required
  compartment_id = var.use_existing_vault ? var.vault_compartment_id : var.compartment_id
  secret_content {
      #Required
      content_type = "BASE64"

      #Optional
      content = base64encode(random_password.wallet_password.result)
      name = "db_wallet_password_${var.application_name}_${formatdate("MMDDhhmm", timestamp())}"
  }
  secret_name ="db_wallet_password_${var.application_name}_${formatdate("MMDDhhmm", timestamp())}"
  vault_id = var.use_existing_vault ? var.vault_id : oci_kms_vault.app_vault[0].id
  key_id = var.use_existing_vault ? var.key_id : oci_kms_key.app_key[0].id
}
