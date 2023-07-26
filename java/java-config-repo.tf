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

resource "null_resource" "war_specific_files" {
  depends_on = [ null_resource.create_config_repo ]
  
  # copy server.xml to app directory
  provisioner "local-exec" {
    command = "cp server.xml ./${local.config_repo_name}/server.xml"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # add server.xml to git
  provisioner "local-exec" {
    command = "git add server.xml"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  # copy catalina.sh to app directory
  provisioner "local-exec" {
    command = "cp catalina.sh ./${local.config_repo_name}/catalina.sh"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # add catalina.sh to git
  provisioner "local-exec" {
    command = "git add catalina.sh"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }

  count = (var.application_type == "WAR") ? 1 : 0
}

resource "null_resource" "language_specific_files" {
 
 depends_on = [ 
  null_resource.create_config_repo,
  null_resource.war_specific_files 
  ]

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

  # add keystore to git
  provisioner "local-exec" {
    command = "git add ./self.keystore"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }
 
}
