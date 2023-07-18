# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
# this file creates the container instances that tun the application


# create container instances
resource "oci_container_instances_container_instance" "app_container_instance" {
  depends_on = [
    oci_devops_build_run.create_docker_image,
    oci_core_subnet.app_oci_core_subnet,
    oci_core_network_security_group.app_nsg
  ]
  availability_domain = var.availability_domain
  compartment_id = var.compartment_id
  containers {
    image_url = local.image-latest-tag
    display_name = "${local.instance-name}-${count.index}container"
    environment_variables = merge(local.env_variables, local.other_env_variables)
  }

  shape = var.shape
  shape_config {
    memory_in_gbs = var.memory_in_gbs
    ocpus = var.ocpus
  }
  vnics {
      subnet_id = local.app_subnet_id
      nsg_ids = [oci_core_network_security_group.app_nsg.id]
  }
  display_name = "${local.instance-name}-${count.index}"

  count = var.nb_copies
}
