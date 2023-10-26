# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# creates load balancer and back ends
resource "oci_load_balancer_load_balancer" "flexible_loadbalancer" {
  shape          = "flexible"
  compartment_id = var.compartment_id

  subnet_ids = [
    local.lb_subnet_id
  ]
  network_security_group_ids = [oci_core_network_security_group.lb_nsg.id]

  shape_details {
    maximum_bandwidth_in_mbps = var.maximum_bandwidth_in_mbps
    minimum_bandwidth_in_mbps = var.minimum_bandwidth_in_mbps
  }

  dynamic "reserved_ips" {
    for_each = var.use_reserved_ip_address ? [1] : []
    content {
      id = data.oci_core_public_ip.reserved_ip[0].id
    }
  }

  is_private = var.open_https_port ? false : true
  display_name = local.load-balancer-name
}

resource "oci_load_balancer_backend_set" "load_balancer_backend_set" {
  depends_on = [
    # oci_core_image.app_image,
    oci_load_balancer_certificate.backend_certificate
  ]
  name             = "${var.application_name}_bset"
  load_balancer_id = oci_load_balancer_load_balancer.flexible_loadbalancer.id
  policy           = "ROUND_ROBIN"

  health_checker {
    port                = var.exposed_port
    protocol            = "HTTP"
    url_path            = var.health_checker_url_path
    return_code         = var.health_checker_return_code
    timeout_in_millis   = var.lb_health_check_timeout_in_millis
    interval_ms         = var.lb_health_check_interval_ms
    retries             = var.lb_health_check_retries
  }

  ssl_configuration {
#    certificate_ids = oci_load_balancer_certificate.backend_certificate.id
    certificate_name = oci_load_balancer_certificate.backend_certificate.certificate_name
    protocols = ["TLSv1.1", "TLSv1.2"]
  }

  # session affinity
  dynamic "lb_cookie_session_persistence_configuration" {
    for_each = var.session_affinity == "Enable load balancer cookie persistence" ? [1] : []
    content {
      cookie_name = var.session_affinity_cookie_name
    }
  }

  dynamic "session_persistence_configuration" {
    for_each = var.session_affinity == "Enable application cookie persistence" ? [1] : []
    content {
      cookie_name = var.session_affinity_cookie_name
    }
  }

}

resource "oci_load_balancer_certificate" "backend_certificate" {
    #Required
    certificate_name =  "backend-certificate"
    load_balancer_id = oci_load_balancer_load_balancer.flexible_loadbalancer.id
    ca_certificate = (local.use-image 
      ? var.ca_pem
      : tls_self_signed_cert.self_signed_certificate[0].cert_pem)
    private_key = (local.use-image 
      ? var.private_key_pem
      : tls_private_key.rsa_private_key[0].private_key_pem)
    public_certificate = (local.use-image 
      ? var.cert_pem
      : tls_self_signed_cert.self_signed_certificate[0].cert_pem)

    lifecycle {
        create_before_destroy = true
    }
}

resource "oci_load_balancer_backend" "load_balancer_backend" {
  depends_on = [
    oci_load_balancer_backend_set.load_balancer_backend_set
  ]
  load_balancer_id = oci_load_balancer_load_balancer.flexible_loadbalancer.id
  backendset_name  = oci_load_balancer_backend_set.load_balancer_backend_set.name
  ip_address       = oci_container_instances_container_instance.app_container_instance[count.index].vnics[0].private_ip
  port             = var.exposed_port
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
  count            = var.nb_copies
}

resource "oci_load_balancer_listener" "listener_https" {
  depends_on = [
    oci_load_balancer_backend_set.load_balancer_backend_set
  ]
  default_backend_set_name = oci_load_balancer_backend_set.load_balancer_backend_set.name
  load_balancer_id = oci_load_balancer_load_balancer.flexible_loadbalancer.id
  name = "${var.application_name}_https"
  port = 443
  protocol = "HTTP"

  ssl_configuration {
    certificate_ids = [var.certificate_ocid]
    protocols = ["TLSv1.2"]
    cipher_suite_name = var.lb_listener_cypher_suite
    verify_peer_certificate = false
    verify_depth = 0
  }
  count = (var.open_https_port ? 1 : 0)
}

resource "oci_dns_rrset" "subdomain_rrset" {
  #Required
  domain = local.domain_name
  rtype = "A"
  zone_name_or_id = data.oci_dns_zones.zones.zones[0].id
  compartment_id = var.dns_compartment

  items {
    domain = local.domain_name
    rdata = oci_load_balancer_load_balancer.flexible_loadbalancer.ip_address_details[0].ip_address
    rtype = "A"
    ttl = 30
  }
  count = (var.create_fqdn ? 1 : 0)
}

