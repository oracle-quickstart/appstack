# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# # IAM object must be created in home region
# resource "tls_private_key" "provider_key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "oci_identity_api_key" "provider_key" {
#     provider = oci.home-provider
#     key_value = tls_private_key.provider_key.public_key_pem
#     user_id = var.current_user_ocid
# }

# provider "oci" {
#   region = lookup(data.oci_identity_regions.home_region.regions[0], "name")
#   alias = "home-provider"
#   tenancy_ocid = "${var.tenancy_ocid}"
#   user_ocid = "${var.current_user_ocid}"
#   fingerprint = tls_private_key.provider_key.public_key_fingerprint_md5
#   private_key_path = tls_private_key.provider_key.private_key_pem
# }

# Allow container instances to download images from container registry
resource "oci_identity_dynamic_group" "container_instance_group" {
#  provider = oci.home-provider
  compartment_id = var.tenancy_ocid
  description = "ci-${var.application_name}"
  matching_rule = "ALL {resource.type='computecontainerinstance'}"
  name = "ci-${var.application_name}"
}

# Container instances dynamic groups
resource "oci_identity_policy" "container_instances_read_repo" {
  depends_on = [ oci_identity_dynamic_group.container_instance_group ]
#  provider = oci.home-provider
  compartment_id = var.tenancy_ocid
  description = "ci-read-repo-${var.application_name}"
  name = "ci-read-repo-${var.application_name}"
  statements = [
    "Allow dynamic-group 'ci-${var.application_name}' to read repos in tenancy"
  ]  
}

# creates service user and policies
resource "oci_identity_tag_namespace" "application_tag_namespace" {
#  provider = oci.home-provider
  compartment_id = var.compartment_id
  description = "Application"
  name = "application-${var.application_name}"
}

resource "oci_identity_tag" "applciation_name_tag" {
#  provider = oci.home-provider
  description = "Application name"
  name = "name"
  tag_namespace_id = oci_identity_tag_namespace.application_tag_namespace.id
}

# Create an authentication token for user to connect to repositories
resource "oci_identity_auth_token" "auth_token" {
#  provider = oci.home-provider
  description = "Authentication token for ${var.application_name}"
  user_id = var.current_user_ocid
  count = (var.create_token ? 1 : 0)
}

resource "oci_identity_dynamic_group" "devops_dynamic_group" {
#  provider = oci.home-provider
  compartment_id = var.tenancy_ocid
  description = "devops-${var.application_name}"
  matching_rule = "Any {resource.type = 'devopsdeploypipeline', resource.type = 'devopsbuildpipeline', resource.type = 'devopsrepository', resource.type = 'devopsconnection', resource.type = 'devopstrigger'}"
  name = "devops-${var.application_name}"
  count = (local.use-image ? 0 : 1)
}

resource "oci_identity_policy" "devops_secrets_policy" {
#  provider = oci.home-provider
  compartment_id = var.tenancy_ocid
  description = "allow-devops-manage-secrets-${var.application_name}"
  name = "allow-devops-manage-secrets-${var.application_name}"
  statements = [
    "Allow dynamic-group 'devops-${var.application_name}' to read secret-family in tenancy",
    "Allow dynamic-group 'devops-${var.application_name}' to manage devops-family in tenancy",
    "Allow dynamic-group 'devops-${var.application_name}' to manage all-resources in tenancy"
  ]
  count = (local.use-image ? 0 : 1)
}


