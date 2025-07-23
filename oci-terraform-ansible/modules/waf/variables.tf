variable "compartment_id" {
  description = "The OCID of the compartment"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "test-ext"
}

variable "load_balancer_id" {
  description = "The OCID of the load balancer to associate with the WAF policy"
  type        = string
}

variable "allowed_paths" {
  description = "List of paths to allow through the WAF"
  type        = list(string)
  default     = ["/ords/r/marinedataregister"]
}

variable "waf_display_name" {
  description = "Display name for the WAF policy"
  type        = string
  default     = "tomcat-waf-policy"
}

variable "waf_policy_tags" {
  description = "Tags for the WAF policy"
  type        = map(string)
  default     = {}
}