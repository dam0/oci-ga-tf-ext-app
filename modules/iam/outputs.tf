# IAM Module Outputs

output "load_balancer_dynamic_group_id" {
  description = "The OCID of the load balancer dynamic group"
  value       = var.create_load_balancer_policies ? oci_identity_dynamic_group.load_balancer_service[0].id : null
}

output "load_balancer_service_policy_id" {
  description = "The OCID of the load balancer service policy"
  value       = var.create_load_balancer_policies ? oci_identity_policy.load_balancer_service_policy[0].id : null
}

output "load_balancer_dynamic_group_policy_id" {
  description = "The OCID of the load balancer dynamic group policy"
  value       = var.create_load_balancer_policies && var.enable_dynamic_group_policies ? oci_identity_policy.load_balancer_dynamic_group_policy[0].id : null
}

output "waf_service_policy_id" {
  description = "The OCID of the WAF service policy"
  value       = var.create_waf_policies ? oci_identity_policy.waf_service_policy[0].id : null
}

output "health_check_service_policy_id" {
  description = "The OCID of the health check service policy"
  value       = var.create_health_check_policies ? oci_identity_policy.health_check_service_policy[0].id : null
}