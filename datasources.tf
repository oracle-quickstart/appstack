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

# dockerfile used to create image
data "template_file" "dockerfile" {
  template = "${var.application_type == "JAR" ? file("${path.module}/Dockerfile-jar.template") : file("${path.module}/Dockerfile-war.template")}"
  vars = {
    namespace = "${local.namespace}"
    bucket_name = "${local.bucket_name}"
    keystore_password = random_password.keystore_password.result
    application_name = var.application_name
    private_data_key = data.oci_apm_data_keys.private_key.data_keys[0].value
    endpoint = oci_apm_apm_domain.app_apm_domain.data_upload_endpoint 
    port_property = var.port_property
    vm_options = (var.vm_options != null && var.vm_options != "" ? format("\"%s\", ", replace(var.vm_options, " " , "\", \"")) : "")
    program_arguments = (var.program_arguments != null && var.program_arguments != "" ? format(", \"%s\" ", replace(trimspace(var.program_arguments, " ", ","))): "")
    keystore_property = var.keystore_property
    key_alias_property = var.key_alias_property
    keystore_password_property = var.keystore_password_property
    keystore_type_property = var.keystore_type_property,
    exposed_port = var.exposed_port
  }
}

data "template_file" "server_xml" {
  template = file("${path.module}/server.xml.template")
  vars = {
    keystore_password = random_password.keystore_password.result
    exposed_port = var.exposed_port
  }
  count = (var.application_type == "WAR") ? 1 : 0
}

data "template_file" "catalina_sh" {
  template = file("${path.module}/catalina.sh.template")
  vars = {
    vm_options = var.vm_options
  }
  count = (var.application_type == "WAR") ? 1 : 0
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

# build spec file
data "template_file" "oci_build_config" {
  depends_on = [
    oci_vault_secret.auth_token_secret
  ]
  template = "${(local.use-repository ? file("${path.module}/build-repo.yaml.template") : file("${path.module}/build-artifact.yaml.template"))}"
  vars = {
    image_remote_tag = "${local.image-remote-tag}"
    container_registry_repo = "${local.container-registry-repo}"
    login = local.login_container
    build_command = var.build_command
    artifact_location = var.artifact_location
    oci_token = local.auth_token_secret
    repo_name = (local.use-repository ? data.oci_devops_repository.devops_repository[0].name : "")
    config_repo_name = local.config_repo_name
    artifactId = (local.use-artifact ? var.artifact_id : "")
    registryId = (local.use-artifact ? var.registry_id : "")
    fileName = (var.application_type == "WAR" ? "app.war" : "app.jar")
    db_username = local.username
    db_connection_url = local.connection_str
    db_user_password = oci_vault_secret.db_user_password.id
    wallet_password = oci_vault_secret.db_wallet_password.id
  }
}

# build spec file
data "template_file" "oci_deploy_config" {
  depends_on = [
    oci_vault_secret.auth_token_secret
  ]
  template = "${file("${path.module}/deploy.yaml.template")}"
  vars = {
    oci_token = local.auth_token_secret
    config_repo_url = local.config_repo_url
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
    "backend_set_name" = "${local.load-balancer-name}_bset"
    "load_balancer_id" = oci_load_balancer.flexible_loadbalancer.id
    "container_instance_id" = oci_container_instances_container_instance.app_container_instance[count.index].id
  }
  count = var.nb_copies
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