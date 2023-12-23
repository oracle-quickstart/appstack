# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# DEVOPS create the application image and push to registry

# create container registry in case the application is not an image (so
# either source code or artifact)
resource "oci_artifacts_container_repository" "application-container-repository" {
  compartment_id = local.use-artifact ? var.devops_compartment : var.compartment_id
  display_name = local.repository-name

  is_immutable = false
  is_public = false
  count = local.use-image ? 0 : 1 # not an image
}

# creates the key pair that for OCI config file
resource "tls_private_key" "api_key_pair" {
  algorithm   = "RSA"
  count = length(data.oci_identity_api_keys.dbconnection_api_key.api_keys) == 0 ? 1 : 0
}

# creates the API Key
resource "oci_identity_api_key" "dbconnection_api_key" {
  key_value = tls_private_key.api_key_pair[0].public_key_pem
  user_id = var.current_user_ocid
  count = (length(data.oci_identity_api_keys.dbconnection_api_key.api_keys) == 0 ? 1 : 0)
}

# if the app is an artifact (jar/war), we need to create a topic in order
# to create a project in devops to host the config repo
resource "oci_ons_notification_topic" "topic" {
  compartment_id = var.devops_compartment
  name = var.application_name
  count = local.use-artifact ? 1 : 0 # app is an artifact
}

# now we can create the project (jar/war case)
resource "oci_devops_project" "project" {
  compartment_id = var.devops_compartment
  name = var.application_name
  notification_config {
    topic_id = oci_ons_notification_topic.topic[0].id
  }
  count = local.use-artifact ? 1 : 0
}

resource "oci_logging_log_group" "devops_log_group" {
  compartment_id = var.devops_compartment
  display_name = "logGroup-${formatdate("MMDDhhmm", timestamp())}"
  count = local.use-artifact ? 1 : 0
}

resource "oci_logging_log" "devops_log" {
  display_name = "log-${formatdate("MMDDhhmm", timestamp())}"
  log_group_id = oci_logging_log_group.devops_log_group[0].id
  log_type     = "SERVICE"
  configuration {
    source {
      category    = "all"
      resource    = oci_devops_project.project[0].id
      service     = "devops"
      source_type = "OCISERVICE"
    }
  }
  is_enabled         = true
  retention_duration = 30
  count = local.use-artifact ? 1 : 0
}


resource "oci_devops_build_pipeline" "build_pipeline" {
  project_id = local.project_id
  description = "Build container image"
  display_name = "${local.application_name}-build"
  count = local.use-repository ? 1 : 0
}

resource "oci_devops_build_pipeline" "build_pipeline_artifact" {
  project_id = local.project_id
  description = "Build container image"
  display_name = "${local.application_name}-build"
  build_pipeline_parameters {
    items {
      default_value = local.use-artifact ? var.artifact_id : "none"
      name = "artifactId"

      #Optional
      description = "Artifact to deploy"
    }
    items {
      default_value = local.use-artifact ? data.oci_artifacts_generic_artifact.app_artifact[0].version : "none"
      name = "artifact_version"

      #Optional
      description = "Artifact version"
    }
  }
  count = local.use-artifact ? 1 : 0
}

# source-code case:
resource "oci_devops_build_pipeline_stage" "repo_build_pipeline_stage" {
  depends_on = [
    oci_devops_repository.config_repo,
    oci_devops_build_pipeline.build_pipeline,
    oci_devops_build_pipeline.build_pipeline_artifact,
    null_resource.commit_config_repo
  ]
  build_pipeline_id = (local.use-artifact ? oci_devops_build_pipeline.build_pipeline_artifact[0].id : oci_devops_build_pipeline.build_pipeline[0].id)
  build_pipeline_stage_predecessor_collection {
    items {
      id = (local.use-artifact ? oci_devops_build_pipeline.build_pipeline_artifact[0].id : oci_devops_build_pipeline.build_pipeline[0].id)
    }
  }
  build_pipeline_stage_type = "BUILD"

  build_source_collection {
    items {
      connection_type = "DEVOPS_CODE_REPOSITORY"
      branch = "main"
      name = oci_devops_repository.config_repo[0].name
      repository_id = oci_devops_repository.config_repo[0].id
      repository_url = oci_devops_repository.config_repo[0].http_url
    }
    items {
      connection_type = "DEVOPS_CODE_REPOSITORY"
      branch = var.branch
      name = data.oci_devops_repository.devops_repository[0].name
      repository_id = data.oci_devops_repository.devops_repository[0].id
      repository_url = data.oci_devops_repository.devops_repository[0].http_url
    }
  }
  build_spec_file = "build_spec.yaml"
  description = "Compile application and build container image"
  display_name = "${data.oci_devops_repository.devops_repository[0].name}-build-stage"
  # this vm is used to execute the pipeline:
  image = var.devops_pipeline_image
  is_pass_all_parameters_enabled = false
  primary_build_source = oci_devops_repository.config_repo[0].name
  stage_execution_timeout_in_seconds = 300
  count = local.use-repository ? 1 : 0
}

# artifact case:
resource "oci_devops_build_pipeline_stage" "art_build_pipeline_stage" {
  depends_on = [
    oci_devops_repository.config_repo,
    oci_devops_build_pipeline.build_pipeline,
    oci_devops_build_pipeline.build_pipeline_artifact,
    null_resource.commit_config_repo
  ]
  build_pipeline_id = (local.use-artifact ? oci_devops_build_pipeline.build_pipeline_artifact[0].id : oci_devops_build_pipeline.build_pipeline[0].id)
  build_pipeline_stage_predecessor_collection {
    items {
      id = (local.use-artifact ? oci_devops_build_pipeline.build_pipeline_artifact[0].id : oci_devops_build_pipeline.build_pipeline[0].id)
    }
  }
  build_pipeline_stage_type = "BUILD"

  build_source_collection {
    items {
      connection_type = "DEVOPS_CODE_REPOSITORY"
      branch = "main"
      name = oci_devops_repository.config_repo[0].name
      repository_id = oci_devops_repository.config_repo[0].id
      repository_url = oci_devops_repository.config_repo[0].http_url
    }
  }
  build_spec_file = "build_spec.yaml"
  description = "Build container image"
  display_name = "${local.application_name}-build-stage"
  image = var.devops_pipeline_image
  is_pass_all_parameters_enabled = false
  primary_build_source = oci_devops_repository.config_repo[0].name
  stage_execution_timeout_in_seconds = 300
  count = local.use-artifact ? 1 : 0
}

# image artifact
resource "oci_devops_deploy_artifact" "container_image_artifact" {
  argument_substitution_mode = "NONE"
  deploy_artifact_type       = "DOCKER_IMAGE"
  project_id                 = local.project_id
  display_name               = "Container image"

  deploy_artifact_source {
    image_uri = local.image-latest-tag
    deploy_artifact_source_type = "OCIR"
  }
}


# push image to container registry
resource "oci_devops_build_pipeline_stage" "push_image_to_container_registry" {
  depends_on = [ 
    oci_devops_build_pipeline_stage.repo_build_pipeline_stage,
    oci_devops_build_pipeline_stage.art_build_pipeline_stage,
    oci_artifacts_container_repository.application-container-repository
  ]
    build_pipeline_id = (local.use-artifact ? oci_devops_build_pipeline.build_pipeline_artifact[0].id : oci_devops_build_pipeline.build_pipeline[0].id)
    build_pipeline_stage_predecessor_collection {
        items {
            id = (local.use-repository ? oci_devops_build_pipeline_stage.repo_build_pipeline_stage[0].id : oci_devops_build_pipeline_stage.art_build_pipeline_stage[0].id)
        }
    }
    build_pipeline_stage_type = "DELIVER_ARTIFACT"

    deploy_pipeline_id = oci_devops_deploy_pipeline.deploy_pipeline.id
    description = "Push image to container registry"
    display_name = "Push image to container registry"

    deliver_artifact_collection {
      items {
        artifact_id = oci_devops_deploy_artifact.container_image_artifact.id
        artifact_name = "application_image"
      }
    }
    is_pass_all_parameters_enabled = false
    count = (local.use-image ? 0 : 1)
}

# artifact or source case:
resource "oci_devops_build_pipeline_stage" "trigger_deployment" {
  depends_on = [ 
    oci_devops_build_run.create_docker_image
  ]
    build_pipeline_id = (local.use-artifact ? oci_devops_build_pipeline.build_pipeline_artifact[0].id : oci_devops_build_pipeline.build_pipeline[0].id)
    build_pipeline_stage_predecessor_collection {
        items {
            id = oci_devops_build_pipeline_stage.push_image_to_container_registry[0].id
        }
    }
    build_pipeline_stage_type = "TRIGGER_DEPLOYMENT_PIPELINE"

    deploy_pipeline_id = oci_devops_deploy_pipeline.deploy_pipeline.id
    description = "Trigger deployment"
    display_name = "trigger-deploy"

    image = var.devops_pipeline_image
    is_pass_all_parameters_enabled = false
    count = (local.use-image ? 0 : 1)
}

resource "oci_devops_trigger" "generated_oci_devops_trigger" {
  depends_on = [
    oci_devops_build_run.create_docker_image
  ]
	actions {
		build_pipeline_id = (local.use-artifact ? oci_devops_build_pipeline.build_pipeline_artifact[0].id : oci_devops_build_pipeline.build_pipeline[0].id)
		type = "TRIGGER_BUILD_PIPELINE"
    filter {
      trigger_source = "DEVOPS_CODE_REPOSITORY"
      events = ["PUSH"]
      include {
        head_ref = var.branch
      }
    }
	}
	display_name = "${local.application_name}-trigger"
	project_id = local.project_id
	repository_id = data.oci_devops_repository.devops_repository[0].id
	trigger_source = "DEVOPS_CODE_REPOSITORY"
  count = local.use-repository ? 1 : 0
}

# run the pipeline
resource "oci_devops_build_run" "create_docker_image" {
  depends_on = [
    oci_devops_build_pipeline_stage.push_image_to_container_registry
  ]
  dynamic "build_run_arguments" {
    for_each = local.use-artifact ? [1] : []
    content {
      items {
        value = local.use-artifact ? var.artifact_id : "none"
        name = "artifactId"
      }
      items {
        value = local.use-artifact ? data.oci_artifacts_generic_artifact.app_artifact[0].version : "none"
        name = "artifact_version"
      }
    }
  }
  build_pipeline_id = (local.use-artifact ? oci_devops_build_pipeline.build_pipeline_artifact[0].id : oci_devops_build_pipeline.build_pipeline[0].id)
  display_name = "triggered-by-terraform"
  count = (local.use-image ? 0 : 1)
}

resource "oci_devops_deploy_artifact" "deploy_yaml_artifact" {
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_type       = "COMMAND_SPEC"
  project_id                 = local.project_id
  display_name               = "Deploy yaml artifact"

  deploy_artifact_source {
    deploy_artifact_source_type = "INLINE"
    base64encoded_content       = "${data.template_file.oci_deploy_config.rendered}${join("\n", [for deploy_script in data.template_file.deploy_script : deploy_script.rendered])}"
  }
}

resource "oci_devops_deploy_pipeline" "deploy_pipeline" {
  project_id   = local.project_id
  description  = "Deploy pipeline"
  display_name = "${local.application_name}-deploy"
}

resource "oci_devops_deploy_stage" "deploy_stage" {
   depends_on = [
    oci_devops_deploy_pipeline.deploy_pipeline
  ]
  description = "Deploy image into compute instance"
  display_name = "deploy-image"
  #Required
  deploy_pipeline_id = oci_devops_deploy_pipeline.deploy_pipeline.id
  deploy_stage_predecessor_collection {
      #Required
      items {
          #Required
          id = oci_devops_deploy_pipeline.deploy_pipeline.id
      }
  }
  deploy_stage_type = "SHELL"
  command_spec_deploy_artifact_id = oci_devops_deploy_artifact.deploy_yaml_artifact.id
  container_config {
    container_config_type = "CONTAINER_INSTANCE_CONFIG"
    network_channel {
      network_channel_type = "SERVICE_VNIC_CHANNEL"
      subnet_id = local.app_subnet_id
      nsg_ids = [oci_core_network_security_group.app_nsg.id]
    }
    shape_name = var.devops_deploy_shape
    shape_config {
      memory_in_gbs = var.devops_memory
      ocpus = var.devops_ocpu
    }
  }
  timeout_in_seconds = 3600
}

# Create a projet to contain deploy pipeline when deploying for container image
resource "oci_ons_notification_topic" "deploy_image_topic" {
  compartment_id = var.devops_compartment
  name = "topic-${local.application_name}"
  count = (local.use-image ? 1 : 0)
}

resource "oci_devops_project" "deploy_image_project" {
  compartment_id = var.devops_compartment
  name = "deploy-${local.application_name}"
  notification_config {
    topic_id = oci_ons_notification_topic.deploy_image_topic[0].id
  }
  count = (local.use-image ? 1 : 0)
}