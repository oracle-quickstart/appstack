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

resource "tls_private_key" "rsa_api_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "oci_identity_api_key" "user_api_key" {
    #Required
    key_value = tls_private_key.rsa_api_key.public_key_pem
    user_id = var.current_user_ocid
}

resource "local_file" "api_private_key" {
  depends_on = [ tls_private_key.rsa_api_key ]
  filename = "${path.module}/api-private-key.pem"
  content = tls_private_key.rsa_api_key.private_key_pem
}

resource "local_file" "ssh_config" {
  filename = "${path.module}/ssh_config"
  content = data.template_file.ssh_config.rendered
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

# Update the config repo with the required bits:
resource "null_resource" "create_config_repo" {
  depends_on = [
    oci_devops_repository.config_repo,
    local_file.dockerfile,
    local_file.wallet,
    local_file.self_signed_certificate,
    local_file.oci_build_config,
    local_file.ssh_config,
    random_password.wallet_password
  ]

  # create .ssh directory
  provisioner "local-exec" {
    command = "mkdir ~/.ssh"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # copy private key
  provisioner "local-exec" {
    command = "cp api-private-key.pem ~/.ssh/private-key.pem"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # copy ssh-config
  provisioner "local-exec" {
    command = "cp ssh_config ~/.ssh/config"
    on_failure = fail
    working_dir = "${path.module}"
  }

  provisioner "local-exec" {
    command = "less ~/.ssh/config"
    on_failure = fail
    working_dir = "${path.module}"
  }

  provisioner "local-exec" {
    command = "less ~/.ssh/private-key.pem"
    on_failure = fail
    working_dir = "${path.module}"
  }

  provisioner "local-exec" {
    command = "chmod 400 ~/.ssh/private-key.pem"
    on_failure = fail
    working_dir = "${path.module}"
  }

  provisioner "local-exec" {
    command = "chmod 600 ~/.ssh/config"
    on_failure = fail
    working_dir = "${path.module}"
  }

  provisioner "local-exec" {
    command = "ls -lai ~/.ssh"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # clone new repository
  provisioner "local-exec" {
    command = "git -c core.sshCommand='ssh -o StrictHostKeyChecking=no' clone ${oci_devops_repository.config_repo[0].ssh_url}"
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

  # copy config to app directory
  provisioner "local-exec" {
    command = "cp build_spec.yaml ./${local.config_repo_name}/build_spec.yaml"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # add build.yaml to git
  provisioner "local-exec" {
    command = "git add build_spec.yaml"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  # copy Dockerfile to app directory
  provisioner "local-exec" {
    command = "cp Dockerfile ./${local.config_repo_name}/Dockerfile"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # add Dockerfile to git
  provisioner "local-exec" {
    command = "git add Dockerfile"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  # copy wallet to app directory
  provisioner "local-exec" {
    command = "cat wallet.zip.b64 | base64 --decode > ./${local.config_repo_name}/wallet.zip"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # add wallet to git
  provisioner "local-exec" {
    command = "git add wallet.zip"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  provisioner "local-exec" {
    command = "openssl pkcs12 -export -in certificate.pem -inkey private-key.pem -name self_signed -password \"pass:${random_password.keystore_password.result}\" > server.p12"
    on_failure = fail
    working_dir = "${path.module}"
  }

  count = (local.use-image ? 0 : 1)
}

resource "null_resource" "commit_config_repo" {

  depends_on = [ null_resource.language_specific_files ]
  
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

  count = (local.use-image ? 0 : 1)
}