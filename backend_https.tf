# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# this file creates the self-signed certificate used to set up the web server
# HTTPS connection

# RSA key of size 4096 bits
resource "tls_private_key" "rsa_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
  count = (local.use-image ? 0 : 1)
}

resource "tls_self_signed_cert" "self_signed_certificate" {
  private_key_pem = tls_private_key.rsa_private_key[0].private_key_pem 

  subject {
    common_name  = "localhost"
  }

  validity_period_hours = 87600

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "cert_signing", 
    "client_auth", 
    "data_encipherment", 
    "digital_signature", 
    "server_auth"
  ]
  count = (local.use-image ? 0 : 1)
}

resource "local_file" "self_signed_certificate" {
  filename = "${path.module}/certificate.pem"
  content = tls_self_signed_cert.self_signed_certificate[0].cert_pem
  count = (local.use-image ? 0 : 1)
}

resource "local_file" "self_signed_private_key" {
  filename = "${path.module}/private-key.pem"
  content = tls_private_key.rsa_private_key[0].private_key_pem
  count = (local.use-image ? 0 : 1)
}

# Keystore password
resource "random_password" "keystore_password" {
  length           = 15
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 0
  special          = false
  numeric          = true
  override_special = "!#%&"
}