# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

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
    program_arguments = (var.program_arguments != null && var.program_arguments != "" ? format(", \"%s\" ", replace(trimspace(var.program_arguments), " ", "\", \"")): "")
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

# build spec file
data "template_file" "oci_build_config" {
  template = "${(local.use-repository ? file("${path.module}/build-repo.yaml.template") : file("${path.module}/build-artifact.yaml.template"))}"
  vars = {
    image_remote_tag = "${local.image-remote-tag}"
    image_latest_tag = "${local.image-latest-tag}"
    image_tag = "${local.image-name}"
    container_registry_repo = "${local.container-registry-repo}"
    login = local.login_container
    build_command = var.build_command
    artifact_location = var.artifact_location
    artifact_path = (local.use-artifact ? data.oci_artifacts_generic_artifact.app_artifact[0].artifact_path : "")
    artifact_version = (local.use-artifact ? data.oci_artifacts_generic_artifact.app_artifact[0].version : "")
    repo_name = (local.use-repository ? data.oci_devops_repository.devops_repository[0].name : "")
    config_repo_name = local.config_repo_name
    artifactId = (local.use-artifact ? var.artifact_id : "")
    registryId = (local.use-artifact ? var.registry_id : "")
    fileName = (var.application_type == "WAR" ? "app.war" : "app.jar")
    db_username = local.username
    db_connection_url = local.escaped_connection_url
    db_user_password = oci_vault_secret.db_user_password.id
    wallet_password = oci_vault_secret.db_wallet_password.id
  }
}


