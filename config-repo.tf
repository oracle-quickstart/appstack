# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# The "config-repo" is used to store the required configuration files and the
# dependent libs such as the tomcat jar in the WAR case, apm jar for monitoring,
# the wallet to connect to ADB-S, etc. If the stack is re-executed Terraform knows
# how to reuse previous resources (update or drop+create).

# creates the git repo called "config-repo"
resource "oci_devops_repository" "config_repo" {
  name = local.config_repo_name
  project_id = local.project_id
  repository_type = "HOSTED"
  default_branch = "main"
  description = "Files needed to create the image and configure the application"
  count = (local.use-image ? 0 : 1)
}

# creates necessary files to configure Docker image
# creates the Dockerfile
resource "local_file" "dockerfile" {
  filename = "${path.module}/Dockerfile"
  content = data.template_file.dockerfile.rendered
}


# creates the OCI config file
resource "local_file" "wallet" {
  filename = "${path.module}/wallet.zip.b64"
  content = oci_database_autonomous_database_wallet.database_wallet.content
}

# creates the OCI config file
resource "local_file" "oci_build_config" {
  filename = "${path.module}/build_spec.yaml"
  content = data.template_file.oci_build_config.rendered
}

# create temporary deploy files that will be concatenated with script
resource "local_file" "deploy_image" {
  filename = "${path.module}/deploy${count.index}.sh"
  content = data.template_file.deploy_script[count.index].rendered

  count = var.nb_copies
}

# Repository used to store deployment shell script
resource "oci_artifacts_repository" "application_repository" {
  compartment_id = var.compartment_id
  is_immutable = true
  repository_type = "GENERIC"
  display_name = "${local.application_name}-repository"
}

resource "oci_generic_artifacts_content_artifact_by_path" "update_container_instance_script" {
  depends_on = [ 
    oci_artifacts_repository.application_repository 
  ]

  artifact_path  = local.deploy_artifact_path
  repository_id    = oci_artifacts_repository.application_repository.id
  version = local.deploy_artifact_version
  source = "${path.module}/update_container_instance.sh"
}