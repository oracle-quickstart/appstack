# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# get database wallet

# Password generator
resource "random_password" "wallet_password" {
  length           = 15
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 0
  special          = false
}

resource "oci_database_autonomous_database_wallet" "database_wallet" {
  depends_on = [
    random_password.wallet_password
  ]
  autonomous_database_id = local.database_ocid
  password = random_password.wallet_password.result
  base64_encode_content = "true"
  generate_type = "SINGLE"
}