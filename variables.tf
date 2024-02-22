# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# variables 
variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}
variable "current_user_ocid" {}

# Compartment / availability domain
variable compartment_id {
  description = "The selected comptartment, by default the users compartment"
  type = string
}

variable "availability_domain" {
  description = "Availabiliy domain"
  type        = string
}

variable "application_name" {
  description = "Application name"
  type = string
}

variable "exposed_port" {
  description = "Exposed port"  
  type = string
  default = "8443"
}

# Database configuration
variable "use_existing_database" {
  type = bool
}

# Existing database 
variable "autonomous_database" {
  description = "Existing autonomous database"
  type = string
  default = "none"
}

# Database user
variable "autonomous_database_user" {
  description = "Existing autonomous database user"
  type = string
  default = "none"
}

# Secret containing database user's password
variable "autonomous_database_password" {
  description = "Existing autonomous database password"
  type = string
  default = ""
}

variable "autonomous_database_admin_password" {
  description = "Existing autonomous database password"
  type = string
  default = ""  
}

# New database
variable "autonomous_database_display_name" {
  description = "Database display name"
  type = string
  default = "none"
}

# The vault where the admin password will be stored
variable "vault_compartment_id" {
  description = "Compartment of the exiting vault"
  type = string
}
variable "vault_id" {
  description = "The vault where the database ADMIN password will be stored"
  type = string
  default = "none"
}

# Encryption key to be used when storing the ADMIN password
variable "key_id" {
  description = "Encryption key used for storing the password"
  type = string
  default = "none"
}

variable "devops_compartment" {
  type = string
  default = ""
  description = "Compartment containing the DevOps project"
}

variable "db_compartment" {
  type = string
  default = ""
  description = "Compartment containing the autonomous database"
}

# OCI devops repository
variable "repo_name" {
  type = string
  default = ""
}

# Branch
variable "branch" {
  type = string
  default = ""
}

# Build command
variable "build_command" {
  type = string
  default = ""
}

# Artifact location
variable "artifact_location" {
  type = string
  default = ""
}

# Number of copies
variable "nb_copies" {
  type = number
}

variable "dns_compartment" {
  type = string
  default = ""
  description = "Compartment containing the DNS Zone and Certificate"
}

variable "certificate_ocid" {
  type = string
  description = "Cerfificate ocid"
  default = "none"
}

variable "subdomain" {
  type = string
  description = "DNS zone"
  default = ""
}

variable "zone" {
  type = string
  description = "DNS zone"
  default = ""
}

variable "application_source" {
  type = string
  description = "source of the application: IMAGE, JAR/WAR, source code"
}

variable "create_fqdn" {
  type = bool
  description = "create a FQDN that points to the load balancer"
}

# Application configuration environment variables
variable "connection_url_env" {
  type = string
  default = ""
}
variable "tns_admin_env" {
  type = string
  default = "TNS_ADMIN"
}
variable "username_env" {
  type = string
  default = ""
}
variable "password_env" {
  type = string
  default = ""
}

variable "use_connection_url_env" {
  type = bool
  default = false
}
variable "use_tns_admin_env" {
  type = bool
  default = false
}
variable "use_username_env" {
  type = bool
  default = false
}
variable "use_password_env" {
  type = bool
  default = false
}

# Network configuration CIDR
variable "vcn_compartment_id" {
  type = string
  default = ""
}
variable "create_new_vcn" {
  type = bool
  default = false
}
variable "existing_vcn_id" {
  type = string
  default = ""
}
variable "vcn_cidr" {
  type = string
  default = "0.0.0.0/0"
}

variable "use_existing_app_subnet" {
  type = bool
  default = false
}
variable "existing_app_subnet_id" {
  type = string
  default = ""
}
variable "app_subnet_cidr" {
  type = string
  default = "0.0.0.0/0"
}

variable "use_existing_db_subnet" {
  type = bool
  default = false
}
variable "existing_db_subnet_id" {
  type = string
  default = ""
}
variable "db_subnet_cidr" {
  type = string
  default = "0.0.0.0/0"
}

variable "use_existing_lb_subnet" {
  type = bool
  default = false
}
variable "existing_lb_subnet_id" {
  type = string
  default = ""
}
variable "lb_subnet_cidr" {
  type = string
  default = "0.0.0.0/0"
}

# Application artifict configuration
variable "artifact_id" {
  type = string
  default = ""
}

variable "registry_id" {
  type = string
  default = ""
}

# Application image configuration
variable "image_path" {
  type = string
  default = ""
}

# Container instances
variable "shape" {
  type = string
  default = "CI.Standard.E3.Flex"
}

variable "memory_in_gbs" {
  type = number
  default = "16"
}

variable "ocpus" {
  type = number
  default = 2
}

# Load balancer
variable "use_default_lb_configuration" {
  type = bool
  default = false
  
}
variable "maximum_bandwidth_in_mbps" {
  type = number
  default = 10
}

variable "minimum_bandwidth_in_mbps" {
  type = number
  default = 10
}

variable "health_checker_url_path" {
  type = string
  default = "/"
}

variable "health_checker_return_code" {
  type = number
  default = 200
}

# database
variable "data_storage_size_in_tbs" {
  type = number
  default = 1
}

variable "ocpu_count" {
  type = number
  default = 1
}

variable "open_https_port" {
  type = bool
  default = false
}

variable "env_variables" {
  type = list(string)
  description = "Environment variables"
  default = ["CONN_URL", "USERNAME", "PASSWORD", "WALLET"]
}

variable "other_environment_variables" {
  type = string
  description = "Other envoronment variables"  
  default = ""
}

variable "program_arguments" {
  type = string
  description = "Program arguments"  
  default = ""
}

variable "enable_session_affinity" {
  type = bool
  description = "Enable session affinity"
  default = false
}

variable "session_affinity" {
  type = string
  description = "Session affinity"
  default = "NONE"
}

variable "session_affinity_cookie_name" {
  type = string
  description = "Session affinity cookie name"
  default = "X-Oracle-BMC-LBS-Route"
}

variable "cert_pem" {
  type = string
  description = "Certificate"
  default = ""
}

variable "ca_pem" {
  type = string
  description = "CA Certificate"
  default = ""
}

variable "private_key_pem" {
  type = string
  description = "Private key"
  default = ""
}

variable "use_existing_vault" {
  type = bool
  description = "Use existing vault"
  default = true
}

variable "new_vault_display_name" {
  type = string
  description = "Display name of the key vault"
  default = ""
}

variable "is_free_tier" {
  type = bool
  description = "APM free tier"
  default = false
}

locals {
  # application name with branch
  application_name = (var.branch == "" ? var.application_name : "${var.application_name}-${var.branch}")
  # region_key
  region_key = lower(data.oci_identity_regions.current_region.regions[0].key)
  # namespace
  namespace = "${data.oci_objectstorage_namespace.os_namespace.namespace}"
  # Service username
  service-username = data.oci_identity_user.current_user.name
  # login, tenancy + username (DevOps)
  login = "${data.oci_identity_tenancy.tenancy.name}/${local.service-username}"
  # ssh login
  ssh_login = "${local.service-username}@${data.oci_identity_tenancy.tenancy.name}"
  # login, namespace + username (Container Registry)
  login_container = "${local.namespace}/${local.service-username}"
  # Container registry url
  container-registry-repo = "${local.region_key}.ocir.io"
  # image name
  image-name = "${local.application_name}-image"
  # load balancer name
  load-balancer-name = "${local.application_name}-lb"
  # repository name
  repository-name = lower("${local.application_name}-repository")
  # instance name
  instance-name = "${local.application_name}-instance"
  # vcn name
  vcn-name = "${local.application_name}-vcn"
  # internet gateway name
  internet-gateway-name = "${local.application_name}-internet-gateway"
  # vcn DNS label
  vcn-dns-label = "vcn${formatdate("MMDDhhmm", timestamp())}"
  # subnet DNS label
  app-subnet-dns-label = "app${formatdate("MMDDhhmm", timestamp())}"
  # subnet DNS label
  lb-subnet-dns-label = "lb${formatdate("MMDDhhmm", timestamp())}"
  # subnet DNS label
  db-subnet-dns-label = "db${formatdate("MMDDhhmm", timestamp())}"
  # full image path on registry
  image-remote-tag = (!local.use-image
        ? "${local.container-registry-repo}/${local.namespace}/${local.repository-name}"
        : var.image_path)
  # full image path on registry
  image-latest-tag = (!local.use-image
        ? "${local.container-registry-repo}/${local.namespace}/${local.repository-name}:latest"
        : var.image_path)
  # bucket name
  bucket_name = "${local.application_name}-bucket"
  
  # dbconnection_api_key_pem = (
  #   length(data.oci_identity_api_keys.dbconnection_api_key.api_keys) == 0
  #     ? oci_identity_api_key.dbconnection_api_key[0].key_value
  #     : data.oci_identity_api_keys.dbconnection_api_key.api_keys[0].key_value
  # )
  config_repo_name = "${local.application_name}-config"
  # database OCID
  database_ocid = (var.use_existing_database ? var.autonomous_database : oci_database_autonomous_database.database[0].id)
  # database username
  username = (var.use_existing_database ? var.autonomous_database_user : "ADMIN")
  # database password
  password = (var.use_existing_database ? var.autonomous_database_password : var.autonomous_database_admin_password)
  # connection string index to use 0 for mTLS 5 for TLS
  conn_url_index = 0
  # database connection string
  escaped_connection_url = (
    var.use_existing_database 
      ? replace(replace(data.oci_database_autonomous_database.autonomous_database.connection_strings[0].profiles[local.conn_url_index].value, "description= ", "description="), "\"", "\\\"")
      : replace(replace(oci_database_autonomous_database.database[0].connection_strings[0].profiles[local.conn_url_index].value, "description= ", "description="), "\"", "\\\"")
  )
  # FQDN
  domain_name = "${var.subdomain}.${var.zone}"
  # use repository (source code in devops)
  use-repository = (var.application_source == "SOURCE_CODE")
  # use artifact (jar or war)
  use-artifact = (var.application_source == "ARTIFACT")
  # use image (container image)
  use-image = (var.application_source == "IMAGE")
  # project_id
  project_id = (local.use-image ? oci_devops_project.deploy_image_project[0].id : (local.use-repository ? data.oci_devops_repository.devops_repository[0].project_id : oci_devops_project.project[0].id))
  # filtered env variables
  env_variables_list = [
    for env in var.env_variables : 
    (env == "CONN_URL" ? {name : "${var.connection_url_env}", value : local.driver_connection_url} :
    (env == "USERNAME" ? {name : "${var.username_env}", value : local.username} :
    (env == "PASSWORD" ? {name : "${var.password_env}", value : local.password} :
    (env == "WALLET" ? {name : "${var.tns_admin_env}", value : local.wallet_path} : null))))
     if ((env == "CONN_URL" && var.use_connection_url_env) || 
         (env == "USERNAME" && var.use_username_env) ||
         (env == "PASSWORD" && var.use_password_env) ||
         (env == "WALLET" && (var.use_tns_admin_env || !local.use-image)))]
  # Convert list to map
  env_variables = { for env in local.env_variables_list : env.name => env.value }
  other_env_variables = (var.other_environment_variables != "" ? { for env in split(";", var.other_environment_variables) : split("=", env)[0] => split("=", env)[1] } : {})
  deploy_artifact_path = "${local.application_name}-deploy-script"
  deploy_artifact_version = "1.0.0"
  vcn_id = (var.create_new_vcn ? oci_core_vcn.app_oci_core_vnc[0].id : var.existing_vcn_id)
  app_subnet_id = (var.use_existing_app_subnet ? var.existing_app_subnet_id : oci_core_subnet.app_oci_core_subnet[0].id)
  db_subnet_id = (var.use_existing_db_subnet ? var.existing_db_subnet_id : (var.use_existing_database ? "" : oci_core_subnet.db_oci_core_subnet[0].id))
  lb_subnet_id = (var.use_existing_lb_subnet ? var.existing_lb_subnet_id : oci_core_subnet.lb_oci_core_subnet[0].id)
  app_subnet_cidr = data.oci_core_subnet.app_subnet.cidr_block 
  db_subnet_cidr = (var.use_existing_database ? "" : data.oci_core_subnet.db_subnet[0].cidr_block)
  lb_subnet_cidr = data.oci_core_subnet.lb_subnet.cidr_block 
  create_service_gateway = (length(data.oci_core_service_gateways.existing_service_gateways.service_gateways) == 0 ? true : false)
  service_gateway = (local.create_service_gateway ? oci_core_service_gateway.service_gateway : data.oci_core_service_gateways.existing_service_gateways.service_gateways)
  create_internet_gateway = (length(data.oci_core_internet_gateways.existing_internet_gateways.gateways) == 0 ? true : false)
  internet_gateway = (local.create_internet_gateway ? oci_core_internet_gateway.app_oci_core_internet_gateway : data.oci_core_internet_gateways.existing_internet_gateways.gateways)

}
