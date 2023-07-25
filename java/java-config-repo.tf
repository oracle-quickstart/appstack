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
    random_password.wallet_password
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
    random_password.wallet_password
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
