# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# dockerfile used to create image
data "template_file" "dockerfile" {
  template = file("${path.module}/Dockerfile-dotnet.template")
  vars = {
    namespace = "${local.namespace}"
    bucket_name = "${local.bucket_name}"
    keystore_password = random_password.keystore_password.result
    application_name = var.application_name
    private_data_key = data.oci_apm_data_keys.private_key.data_keys[0].value
    endpoint = oci_apm_apm_domain.app_apm_domain.data_upload_endpoint
    program_arguments = (var.program_arguments != null && var.program_arguments != "" ? format(", \"%s\" ", replace(trimspace(var.program_arguments), " ", "\", \"")): "")
    exposed_port = var.exposed_port
    dll_name = local.dll_name
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
    image_latest_tag = "${local.image-latest-tag}"
    image_tag = "${local.image-name}"
    container_registry_repo = "${local.container-registry-repo}"
    login = local.login_container
    build_command = var.build_command
    artifact_location = local.output_path
    artifact_path = (local.use-artifact ? data.oci_artifacts_generic_artifact.app_artifact[0].artifact_path : "")
    artifact_version = (local.use-artifact ? data.oci_artifacts_generic_artifact.app_artifact[0].version : "")
    oci_token = local.auth_token_secret
    repo_name = (local.use-repository ? data.oci_devops_repository.devops_repository[0].name : "")
    config_repo_name = local.config_repo_name
    artifactId = (local.use-artifact ? var.artifact_id : "")
    registryId = (local.use-artifact ? var.registry_id : "")
    fileName = "app.zip"
    db_username = local.username
    db_connection_url = local.escaped_connection_url
    db_user_password = oci_vault_secret.db_user_password.id
    wallet_password = oci_vault_secret.db_wallet_password.id
  }
}


