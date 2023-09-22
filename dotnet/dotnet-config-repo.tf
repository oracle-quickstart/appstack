# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

resource "null_resource" "language_specific_files" {
 
 depends_on = [ 
  null_resource.create_config_repo 
  ]

  # copy certificate
  provisioner "local-exec" {
    command = "cp server.p12 ./${local.config_repo_name}/servercert.pfx"
    on_failure = fail
    working_dir = "${path.module}"
  }

  # add certificate to git
  provisioner "local-exec" {
    command = "git add ./servercert.pfx"
    on_failure = fail
    working_dir = "${path.module}/${local.config_repo_name}"
  }
  count = (local.use-image ? 0 : 1)
}