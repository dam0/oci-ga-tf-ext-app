output "load_balancer_id" {
  description = "The OCID of the load balancer"
  value       = oci_load_balancer_load_balancer.lb.id
}

output "load_balancer_ip" {
  description = "The IP address of the load balancer"
  value       = oci_load_balancer_load_balancer.lb.ip_address_details[0].ip_address
}

output "load_balancer_public_ip" {
  description = "The public IP address of the load balancer (if not private)"
  value       = var.is_private ? null : oci_load_balancer_load_balancer.lb.ip_address_details[0].ip_address
}

output "load_balancer_shape" {
  description = "The shape of the load balancer"
  value       = oci_load_balancer_load_balancer.lb.shape
}

output "load_balancer_state" {
  description = "The current state of the load balancer"
  value       = oci_load_balancer_load_balancer.lb.state
}

output "http_listener_name" {
  description = "The name of the HTTP listener"
  value       = oci_load_balancer_listener.http_listener.name
}

output "https_listener_name" {
  description = "The name of the HTTPS listener"
  value       = oci_load_balancer_listener.https_listener.name
}

output "backend_set_name" {
  description = "The name of the backend set"
  value       = oci_load_balancer_backend_set.tomcat_backend_set.name
}

output "backend_servers" {
  description = "List of backend server IP addresses"
  value       = [for backend in oci_load_balancer_backend.tomcat_backends : backend.ip_address]
}

output "certificate_ocid" {
  description = "The OCID of the certificate used for HTTPS"
  value       = var.certificate_ocid
}

output "http_redirect_rule_set_name" {
  description = "The name of the HTTP to HTTPS redirect rule set"
  value       = oci_load_balancer_rule_set.http_to_https_redirect.name
}

output "load_balancer_fqdn" {
  description = "The FQDN of the load balancer (for DNS configuration)"
  value       = "${oci_load_balancer_load_balancer.lb.display_name}.${var.compartment_id}.oraclecloud.com"
}

# WAF Outputs
output "waf_policy_id" {
  description = "The OCID of the WAF policy (if enabled)"
  value       = var.enable_waf ? oci_waf_web_app_firewall_policy.tomcat_waf_policy[0].id : null
}

output "waf_id" {
  description = "The OCID of the WAF (if enabled)"
  value       = var.enable_waf ? oci_waf_web_app_firewall.tomcat_waf[0].id : null
}

output "waf_enabled" {
  description = "Whether WAF is enabled"
  value       = var.enable_waf
}

output "waf_allowed_paths" {
  description = "List of allowed paths in WAF"
  value       = var.waf_allowed_paths
}