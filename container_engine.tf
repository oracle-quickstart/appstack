resource "oci_containerengine_cluster" "generated_oci_containerengine_cluster" {
	cluster_pod_network_options {
		cni_type = "OCI_VCN_IP_NATIVE"
	}
	compartment_id = var.compartment_id
	endpoint_config {
		is_public_ip_enabled = false
		nsg_ids = [oci_core_network_security_group.app_nsg.id]
		subnet_id = oci_core_subnet.app_oci_core_subnet.id
	}
	kubernetes_version = "v1.27.2"
	name = "${var.application_name}-cluster"
	options {
		service_lb_subnet_ids = [oci_core_subnet.lb_oci_core_subnet.id]
	}
	type = "ENHANCED_CLUSTER"
	vcn_id = local.vcn_id
}

resource "oci_containerengine_virtual_node_pool" "create_virtual_node_pool_details0" {
	cluster_id = oci_containerengine_cluster.generated_oci_containerengine_cluster.id
	compartment_id = compartment_id
	name = "${var.application_name}-pool"
	initial_virtual_node_labels {
		key = "name"
		value = "${var.application_name}-pool"
	}
	placement_configurations {
		availability_domain = var.availability_domain
		fault_domain = ["FAULT-DOMAIN-1"]
		subnet_id = local.app_subnet
	}
	pod_configuration {
		shape = "Pod.Standard.E4.Flex"
		subnet_id = local.app_subnet
	}
	size = var.nb_copies
}

# resource "oci_dns_rrset" "subdomain_rrset" {
#   #Required
#   domain = local.domain_name
#   rtype = "A"
#   zone_name_or_id = data.oci_dns_zones.zones.zones[0].id
#   compartment_id = var.dns_compartment

#   items {
#     domain = local.domain_name
#     rdata = oci_load_balancer.flexible_loadbalancer.ip_address_details[0].ip_address
#     rtype = "A"
#     ttl = 30
#   }
#   count = (var.create_fqdn ? 1 : 0)
# }
