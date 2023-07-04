variable "devops_pipeline_image" {
  type = string
  default = "OL7_X86_64_STANDARD_10"
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
  default = "oci-wider-compatible-ssl-cipher-suite-v1"
}

variable "db_version" {
  type = string
  default = "19c"
}

variable "db_license_model" {
  type = string
  default = "LICENSE_INCLUDED"
}