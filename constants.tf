# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
variable "devops_pipeline_image" {
  type = string
  default = "OL8_X86_64_STANDARD_10"
}

variable "devops_deploy_shape" {
  type = string
  default = "CI.Standard.E4.Flex"
}

variable "devops_memory" {
  type = number
  default = 2
}

variable "devops_ocpu" {
  type = number
  default = 2
}

variable "lb_health_check_timeout_in_millis" {
  type = number
  default = 3000
}

variable "lb_health_check_interval_ms" {
  type = number
  default = 5000  
}

variable "lb_health_check_retries" {
  type = number
  default = 3
}

variable "lb_listener_cypher_suite" {
  type = string
  default = "oci-tls-11-12-13-wider-ssl-cipher-suite-v1"
}

variable "db_version" {
  type = string
  default = "19c"
}

variable "db_license_model" {
  type = string
  default = "LICENSE_INCLUDED"
}