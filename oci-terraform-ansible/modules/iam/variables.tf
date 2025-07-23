# IAM Module Variables

variable "tenancy_ocid" {
  description = "The OCID of the tenancy"
  type        = string
}

variable "compartment_id" {
  description = "The OCID of the compartment"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "oci-terraform"
}

variable "create_load_balancer_policies" {
  description = "Whether to create load balancer service policies"
  type        = bool
  default     = true
}

variable "enable_dynamic_group_policies" {
  description = "Whether to create dynamic group policies for load balancer"
  type        = bool
  default     = false
}

variable "create_waf_policies" {
  description = "Whether to create WAF service policies"
  type        = bool
  default     = false
}

variable "create_health_check_policies" {
  description = "Whether to create health check service policies"
  type        = bool
  default     = false
}

variable "freeform_tags" {
  description = "Free-form tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags to apply to resources"
  type        = map(string)
  default     = {}
}