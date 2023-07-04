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

# creates the server.xml
resource "local_file" "server_xml" {
  filename = "${path.module}/server.xml"
  content = data.template_file.server_xml[0].rendered
  count = (var.application_type == "WAR") ? 1 : 0
}

# create catalina.sh
resource "local_file" "catalina" {
  filename = "${path.module}/catalina.sh"
  content = data.template_file.catalina_sh[0].rendered
  count = (var.application_type == "WAR") ? 1 : 0
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


# Update the config repo with the required bits in the WAR case:
resource "null_resource" "create_config_repo_war" {
  depends_on = [
    oci_devops_repository.config_repo,
    local_file.dockerfile,
#    local_file.api_key_pem,
#    local_file.oci_config,
    local_file.wallet,
    local_file.self_signed_certificate,
    local_file.oci_build_config,
    random_password.wallet_password,
    oci_identity_policy.user_manage_all_policy
  ]

  # clone new repository
  provisioner "local-exec" {
    command = "git clone ${local.config_repo_url}"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # clone new repository
  provisioner "local-exec" {
    command = "git config --global user.email \"${local.login}\""
    on_failure = fail
    working_dir = "${path.module}"
  }

    # clone new repository
  provisioner "local-exec" {
    command = "git config --global user.name \"${local.service-username}\""
    on_failure = fail
    working_dir = "${path.module}"
  }

  # copy Dockerfile to app directory
  provisioner "local-exec" {
    command = "cp Dockerfile ./${local.config_repo_name}/Dockerfile"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # copy server.xml to app directory
  provisioner "local-exec" {
    command = "cp server.xml ./${local.config_repo_name}/server.xml"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # copy catalina.sh to app directory
  provisioner "local-exec" {
    command = "cp catalina.sh ./${local.config_repo_name}/catalina.sh"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # copy wallet to app directory
  provisioner "local-exec" {
    command = "cat wallet.zip.b64 | base64 --decode > ./${local.config_repo_name}/wallet.zip"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # copy config to app directory
  provisioner "local-exec" {
    command = "cp build_spec.yaml ./${local.config_repo_name}/build_spec.yaml"
    on_failure = fail
    working_dir = "${path.module}"
  }

  provisioner "local-exec" {
    command = "openssl pkcs12 -export -in certificate.pem -inkey private-key.pem -name self_signed -password \"pass:${random_password.keystore_password.result}\" > server.p12"
    on_failure = fail
    working_dir = "${path.module}"
  }

  provisioner "local-exec" {
    command = "keytool -importkeystore -noprompt -srckeystore server.p12 -destkeystore self.keystore -srcstoretype pkcs12 -alias self_signed -srcstorepass \"${random_password.keystore_password.result}\" -deststorepass \"${random_password.keystore_password.result}\""
    on_failure = fail
    working_dir = "${path.module}"
  }

  # copy keystore
  provisioner "local-exec" {
    command = "cp self.keystore ./${local.config_repo_name}/self.keystore"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # add wallet to git
  provisioner "local-exec" {
    command = "git add wallet.zip"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  # add build.yaml to git
  provisioner "local-exec" {
    command = "git add build_spec.yaml"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  # add Dockerfile to git
  provisioner "local-exec" {
    command = "git add Dockerfile"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  # add catalina.sh to git
  provisioner "local-exec" {
    command = "git add catalina.sh"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  # add server.xml to git
  provisioner "local-exec" {
    command = "git add server.xml"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  # add keystore to git
  provisioner "local-exec" {
    command = "git add ./self.keystore"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  # Commit changes
  provisioner "local-exec" {
    command = "git commit -m \"Initial commit by Terraform script\""
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  # Push changes
  provisioner "local-exec" {
    command = "git push"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  count = (var.application_type == "WAR") ? 1 : 0

}

# Update the config repo with the required bits in the JAR case:
resource "null_resource" "create_config_repo_jar" {
  depends_on = [
    oci_devops_repository.config_repo,
    local_file.dockerfile,
#    local_file.api_key_pem,
#    local_file.oci_config,
    local_file.wallet,
    local_file.self_signed_certificate,
    local_file.oci_build_config,
    random_password.wallet_password,
    oci_identity_policy.user_manage_all_policy
  ]

  # clone new repository
  provisioner "local-exec" {
    command = "git clone ${local.config_repo_url}"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # clone new repository
  provisioner "local-exec" {
    command = "git config --global user.email \"${local.login}\""
    on_failure = fail
    working_dir = "${path.module}"
  }

    # clone new repository
  provisioner "local-exec" {
    command = "git config --global user.name \"${local.service-username}\""
    on_failure = fail
    working_dir = "${path.module}"
  }

  # copy Dockerfile to app directory
  provisioner "local-exec" {
    command = "cp Dockerfile ./${local.config_repo_name}/Dockerfile"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # copy wallet to app directory
  provisioner "local-exec" {
    command = "cat wallet.zip.b64 | base64 --decode > ./${local.config_repo_name}/wallet.zip"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # copy config to app directory
  provisioner "local-exec" {
    command = "cp build_spec.yaml ./${local.config_repo_name}/build_spec.yaml"
    on_failure = fail
    working_dir = "${path.module}"
  }

  provisioner "local-exec" {
    command = "openssl pkcs12 -export -in certificate.pem -inkey private-key.pem -name self_signed -password \"pass:${random_password.keystore_password.result}\" > server.p12"
    on_failure = fail
    working_dir = "${path.module}"
  }

  provisioner "local-exec" {
    command = "keytool -importkeystore -noprompt -srckeystore server.p12 -destkeystore self.keystore -srcstoretype pkcs12 -alias self_signed -srcstorepass \"${random_password.keystore_password.result}\" -deststorepass \"${random_password.keystore_password.result}\""
    on_failure = fail
    working_dir = "${path.module}"
  }

  # copy keystore
  provisioner "local-exec" {
    command = "cp self.keystore ./${local.config_repo_name}/self.keystore"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # add wallet to git
  provisioner "local-exec" {
    command = "git add wallet.zip"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  # add build.yaml to git
  provisioner "local-exec" {
    command = "git add build_spec.yaml"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  # add Dockerfile to git
  provisioner "local-exec" {
    command = "git add Dockerfile"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  # add keystore to git
  provisioner "local-exec" {
    command = "git add ./self.keystore"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  # Commit changes
  provisioner "local-exec" {
    command = "git commit -m \"Initial commit by Terraform script\""
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  # Push changes
  provisioner "local-exec" {
    command = "git push"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  count = (var.application_type == "JAR") ? 1 : 0

}


# Repository used to store deployment shell script
resource "oci_artifacts_repository" "application_repository" {
  compartment_id = var.compartment_id
  is_immutable = true
  repository_type = "GENERIC"
  display_name = "${var.application_name}-repository"
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