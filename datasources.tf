# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# grabs information from OCI needed for creating the infrastructure and 
# deploying the application

# region, used for deducting registry url
data "oci_identity_regions" "current_region" {
  filter {
    name   = "name"
    values = [var.region]
  }
}

data "oci_identity_regions" "home_region" {
  filter {
    name = "key"
    values = ["${data.oci_identity_tenancy.tenancy.home_region_key}"]
  }
}

# object storage namespace
data "oci_objectstorage_namespace" "os_namespace" {
  compartment_id = var.tenancy_ocid
}

# used to get the login of the current user to login to the container registry
data "oci_identity_user" "current_user" {
  user_id = var.current_user_ocid
}

data "oci_identity_compartment" "user_compartment" {
    id = var.compartment_ocid
}

# used to get the connection url of the autonomous database
data "oci_database_autonomous_database" "autonomous_database" {
    autonomous_database_id = var.autonomous_database
}

# oci config file
data "template_file" "oci_config" {
  template = "${file("${path.module}/config")}"
  vars = {
    user_ocid=var.current_user_ocid
    fingerprint=(
      length(data.oci_identity_api_keys.dbconnection_api_key.api_keys) == 0
      ? oci_identity_api_key.dbconnection_api_key[0].fingerprint
      : data.oci_identity_api_keys.dbconnection_api_key.api_keys[0].fingerprint)
    tenancy_ocid=var.tenancy_ocid
    region=var.region
  }
}

data "oci_artifacts_generic_artifact" "app_artifact" {
  artifact_id = var.artifact_id
  count = local.use-artifact ? 1 : 0
}

# build spec file
data "template_file" "oci_deploy_config" {
  template = "${file("${path.module}/deploy.yaml.template")}"
  vars = {
    config_repo_name = local.config_repo_name
    artifact_ocid = oci_generic_artifacts_content_artifact_by_path.update_container_instance_script.id
    registry_ocid = oci_artifacts_repository.application_repository.id
    artifact_path = local.deploy_artifact_path
    artifact_version = local.deploy_artifact_version
  }
}

data "template_file" "deploy_script" {
  depends_on = [
    oci_load_balancer.flexible_loadbalancer,
    oci_container_instances_container_instance.app_container_instance
  ]
  template = "${file("${path.module}/deploy.sh.template")}"
  vars = {
    "backend_name" = "${oci_container_instances_container_instance.app_container_instance[count.index].vnics[0].private_ip}:${var.exposed_port}"
    "backend_set_name" = "${var.application_name}_bset"
    "load_balancer_id" = oci_load_balancer.flexible_loadbalancer.id
    "container_instance_id" = oci_container_instances_container_instance.app_container_instance[count.index].id
  }
  count = var.nb_copies
}

data "template_file" "ssh_config" {
  depends_on = [
    local_file.api_private_key
  ]
  template = "${file("${path.module}/ssh_config.template")}"
  vars = {
    "user" = local.ssh_login
  }
}

data "oci_identity_api_keys" "dbconnection_api_key" {
  user_id = var.current_user_ocid
}

data "oci_devops_repository" "devops_repository" {
  repository_id = var.repo_name
  count = local.use-repository ? 1 : 0
}

data "oci_dns_zones" "zones" {
    compartment_id = (var.dns_compartment == "" ? var.compartment_id : var.dns_compartment)
    name = var.zone
    zone_type = "PRIMARY"
}

data "oci_identity_compartment" "compartment" {
     id = var.compartment_id
}

data "oci_identity_compartment" "vault_compartment" {
     id = var.vault_compartment_id
}

data "oci_identity_tenancy" "tenancy" {
    tenancy_id = var.tenancy_ocid
}

data "oci_core_services" "all_oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

data "oci_core_service_gateways" "existing_service_gateways" {
  compartment_id = !var.create_new_vcn ? var.vcn_compartment_id : var.compartment_id
  vcn_id = local.vcn_id
}

data "oci_core_internet_gateways" "existing_internet_gateways" {
  compartment_id = !var.create_new_vcn ? var.vcn_compartment_id : var.compartment_id
  vcn_id = local.vcn_id
}

data "oci_core_vcn" "app_vcn" {
  vcn_id = local.vcn_id
}

data "oci_core_subnet" "app_subnet" {
  subnet_id = local.app_subnet_id
}

data "oci_core_subnet" "db_subnet" {
  subnet_id = local.db_subnet_id
  count = var.use_existing_database ? 0 : 1
}

data "oci_core_subnet" "lb_subnet" {
  subnet_id = local.lb_subnet_id
}