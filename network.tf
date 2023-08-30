# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# network configuraion

#Virtual Cloud Network
resource "oci_core_vcn" "app_oci_core_vnc" {
	cidr_block = var.vcn_cidr
	compartment_id = var.compartment_id
	display_name = local.vcn-name
	dns_label = local.vcn-dns-label
  count = (var.create_new_vcn ? 1 : 0)
}

# Subnet
resource "oci_core_subnet" "app_oci_core_subnet" {
	cidr_block = var.app_subnet_cidr
	compartment_id = var.compartment_id
	display_name = "app-subnet-${formatdate("MMDDhhmm", timestamp())}"
	dns_label = local.app-subnet-dns-label
	route_table_id = oci_core_route_table.private_route_table[count.index].id
	vcn_id = data.oci_core_vcn.app_vcn.id
  # security_list_ids = [oci_core_security_list.app_security_list.id]
  prohibit_internet_ingress = true
  prohibit_public_ip_on_vnic = true
  count = (var.use_existing_app_subnet ? 0 : 1)
}

# Subnet
resource "oci_core_subnet" "lb_oci_core_subnet" {
	cidr_block = var.lb_subnet_cidr
	compartment_id = var.compartment_id
	display_name = "lb-subnet-${formatdate("MMDDhhmm", timestamp())}"
	dns_label = local.lb-subnet-dns-label
	route_table_id = "${data.oci_core_vcn.app_vcn.default_route_table_id}"
	vcn_id = data.oci_core_vcn.app_vcn.id
  prohibit_internet_ingress = var.open_https_port ? false : true
  prohibit_public_ip_on_vnic = var.open_https_port ? false : true
  count = (var.use_existing_lb_subnet ? 0 : 1)
  # security_list_ids = [oci_core_security_list.lb_security_list.id]
}

# Subnet
resource "oci_core_subnet" "db_oci_core_subnet" {
	cidr_block = var.db_subnet_cidr
	compartment_id = var.compartment_id
	display_name = "db-subnet-${formatdate("MMDDhhmm", timestamp())}"
	dns_label = local.db-subnet-dns-label
	route_table_id = "${data.oci_core_vcn.app_vcn.default_route_table_id}"
	vcn_id = data.oci_core_vcn.app_vcn.id
  # security_list_ids = [oci_core_security_list.db_security_list[0].id]
  prohibit_internet_ingress = true
  prohibit_public_ip_on_vnic = true
  count = (!var.use_existing_db_subnet && !var.use_existing_database ? 1 : 0)
}

# Internet Gateway
resource "oci_core_internet_gateway" "app_oci_core_internet_gateway" {
	compartment_id = var.compartment_id
	display_name = "${local.internet-gateway-name}"
	enabled = "true"
	vcn_id = data.oci_core_vcn.app_vcn.id
  count = (var.create_new_vcn ? 1 : (local.create_internet_gateway ? 1 : 0))
}

# Public route table
resource "oci_core_default_route_table" "generated_oci_core_default_route_table" {
	route_rules {
		destination = "0.0.0.0/0"
		destination_type = "CIDR_BLOCK"
		network_entity_id = local.internet_gateway[0].id
	}
	manage_default_resource_id = "${data.oci_core_vcn.app_vcn.default_route_table_id}"
}

# Security list
resource "oci_core_default_security_list" "vcn_security_list" {
  compartment_id = var.compartment_id
  manage_default_resource_id = data.oci_core_vcn.app_vcn.default_security_list_id
  count = (var.create_new_vcn ? 1 : 0)
}

# CSSAP -> Use NSGs instead of security lists
resource "oci_core_network_security_group" "app_nsg" {
  compartment_id = var.compartment_id
  vcn_id = data.oci_core_vcn.app_vcn.id
}

resource "oci_core_network_security_group_security_rule" "app_ingress_https" {
  network_security_group_id = oci_core_network_security_group.app_nsg.id
  direction = "INGRESS"
  protocol = "6"
  description = "load balancer -> application"
  source = local.lb_subnet_cidr
  source_type = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = var.exposed_port
      max = var.exposed_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "app_egress_service" {
  network_security_group_id = oci_core_network_security_group.app_nsg.id
  direction = "EGRESS"
  protocol = "6"
  description = "Access to OCI Services"
  destination = "all-${local.region_key}-services-in-oracle-services-network"
  destination_type = "SERVICE_CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "app_egress_db" {
  network_security_group_id = oci_core_network_security_group.app_nsg.id
  direction = "EGRESS"
  protocol = "6"
  description = "Database access"
  destination = local.db_subnet_cidr
  destination_type = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 1521
      max = 1522
    }
  }
  count = (var.use_existing_database ? 0 : 1)
}

resource "oci_core_network_security_group" "lb_nsg" {
  compartment_id = var.compartment_id
  vcn_id = data.oci_core_vcn.app_vcn.id
}

resource "oci_core_network_security_group_security_rule" "lb_ingress_https" {
  network_security_group_id = oci_core_network_security_group.lb_nsg.id
  direction = "INGRESS"
  protocol = "6"
  description = "Internet -> load balancer"
  source = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
  count = var.open_https_port ? 1 : 0
}

resource "oci_core_network_security_group_security_rule" "lb_egress_https" {
  network_security_group_id = oci_core_network_security_group.lb_nsg.id
  direction = "EGRESS"
  protocol = "6"
  description = "Load balancer -> app"
  destination = local.app_subnet_cidr
  destination_type = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = var.exposed_port
      max = var.exposed_port
    }
  }
}

resource "oci_core_network_security_group" "db_nsg" {
  compartment_id = var.compartment_id
  vcn_id = data.oci_core_vcn.app_vcn.id
  count = var.use_existing_database ? 0 : 1
}

resource "oci_core_network_security_group_security_rule" "db_ingress_mTLS" {
  network_security_group_id = oci_core_network_security_group.db_nsg[0].id
  direction = "INGRESS"
  description = "Mutual TLS"
  protocol = "6"
  source = local.app_subnet_cidr
  source_type = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 1521
      max = 1522
    }
  }
  count = var.use_existing_database ? 0 : 1
}

# create service gateway if new application subnet and service gateway does not exist in VCN
resource "oci_core_service_gateway" "service_gateway" {
  compartment_id = var.compartment_id
  services {
      service_id = data.oci_core_services.all_oci_services.services[count.index].id
  }
  vcn_id = data.oci_core_vcn.app_vcn.id
  display_name = "${local.vcn-name}-service-gateway"
  count = (
    var.create_new_vcn 
      ? 1
      : (!var.use_existing_app_subnet && local.create_service_gateway ? 1 : 0)
  )
}

# Private route table got new application subnet
resource "oci_core_route_table" "private_route_table" {
  compartment_id = var.compartment_id
  vcn_id = data.oci_core_vcn.app_vcn.id

  display_name = "private-route-table"
  route_rules {
      network_entity_id = local.service_gateway[count.index].id

      description = "All services"
      destination = data.oci_core_services.all_oci_services.services[count.index].cidr_block
      destination_type = "SERVICE_CIDR_BLOCK"
  }
  count = (var.use_existing_app_subnet ? 0 : 1)
}
