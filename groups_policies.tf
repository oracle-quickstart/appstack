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

resource "oci_identity_user" "application_user" {
#  provider = oci.home-provider
  compartment_id = var.tenancy_ocid
  description = "Service user for ${var.application_name}"
  name = local.service-username
  # email = "${local.service-username}@yourdomain.com"
}

resource "oci_identity_user_capabilities_management" "application_user_capabilities" {
#  provider = oci.home-provider
  user_id = oci_identity_user.application_user.id

  can_use_api_keys             = "false"
  can_use_auth_tokens          = "true"
  can_use_console_password     = "false"
  can_use_customer_secret_keys = "false"
  can_use_smtp_credentials     = "false"
}

resource "oci_identity_auth_token" "auth_token" {
#  provider = oci.home-provider
  description = "Authentication token for ${var.application_name}"
  user_id = oci_identity_user.application_user.id
}

resource "oci_identity_dynamic_group" "devops_dynamic_group" {
#  provider = oci.home-provider
  compartment_id = var.tenancy_ocid
  description = "devops-${var.application_name}"
  matching_rule = "Any {resource.type = 'devopsdeploypipeline', resource.type = 'devopsbuildpipeline', resource.type = 'devopsrepository', resource.type = 'devopsconnection', resource.type = 'devopstrigger'}"
  name = "devops-${var.application_name}"
  count = (local.use-image ? 0 : 1)
}


# resource "oci_identity_dynamic_group" "instances_dynamic_group" {
#   compartment_id = var.tenancy_ocid
#   description = "instances-${var.application_name}"
#   matching_rule = "all {tag.application.name.value='${var.application_name}'}"
#   name = "instances-${var.application_name}"
# }

 resource "oci_identity_group" "user_group_application" {
#   provider = oci.home-provider
   compartment_id = var.tenancy_ocid
   description = "${var.application_name}-group"
   name = "user-group-${var.application_name}"
 }

 resource "oci_identity_user_group_membership" "user_group_membership" {
#  provider = oci.home-provider
  group_id = oci_identity_group.user_group_application.id
  user_id = oci_identity_user.application_user.id
 }

 resource "oci_identity_policy" "user_manage_all_policy" {
  depends_on = [ oci_identity_group.user_group_application ]
#  provider = oci.home-provider
  compartment_id = var.compartment_id
  description = "allow-user-devops-${var.application_name}"
  name = "allow-user-devops-${var.application_name}"
  statements = [
    "Allow group 'user-group-${var.application_name}' to use devops-repository in compartment ${data.oci_identity_compartment.compartment.name}",
    "Allow group 'user-group-${var.application_name}' to manage repos in compartment ${data.oci_identity_compartment.compartment.name} where ANY {request.permission = 'REPOSITORY_READ', request.permission = 'REPOSITORY_UPDATE', request.permission = 'REPOSITORY_CREATE'}"
  ]
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

resource "oci_identity_policy" "image_access_to_user" {
#  provider = oci.home-provider
  compartment_id = var.compartment_id
  description = "allow-user-pull-image-${var.application_name}"
  name = "allow-user-pull-image-${var.application_name}"
  statements = [
    "Allow group 'user-group-${var.application_name}' to read repos in compartment ${data.oci_identity_compartment.compartment.name}"
  ]
  count = (local.use-image ? 1 : 0)
}

