# this file creates the container instances that tun the application

# wait for policy to be active
resource "time_sleep" "wait_60_seconds" {
  depends_on = [ oci_identity_policy.container_instances_read_repo ]
  create_duration = "60s"
}

# create container instances
resource "oci_container_instances_container_instance" "app_container_instance" {
  depends_on = [
    oci_devops_build_run.create_docker_image,
    oci_core_subnet.app_oci_core_subnet,
    oci_core_network_security_group.app_nsg,
    oci_identity_user_group_membership.user_group_membership,
    oci_identity_policy.image_access_to_user,
    time_sleep.wait_60_seconds
  ]
  availability_domain = var.availability_domain
  compartment_id = var.compartment_id
  containers {
    image_url = local.image-remote-tag
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
