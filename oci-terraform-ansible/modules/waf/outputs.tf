output "waf_policy_id" {
  description = "The OCID of the WAF policy"
  value       = oci_waf_web_app_firewall_policy.waf_policy.id
}

output "waf_id" {
  description = "The OCID of the WAF"
  value       = oci_waf_web_app_firewall.load_balancer_waf.id
}

output "waf_policy_display_name" {
  description = "The display name of the WAF policy"
  value       = oci_waf_web_app_firewall_policy.waf_policy.display_name
}

output "allowed_paths" {
  description = "The paths allowed through the WAF"
  value       = var.allowed_paths
}