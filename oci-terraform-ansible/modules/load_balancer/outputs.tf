output "load_balancer_id" {
  description = "The OCID of the load balancer"
  value       = oci_load_balancer.lb.id
}

output "load_balancer_ip" {
  description = "The IP address of the load balancer"
  value       = oci_load_balancer.lb.ip_address_details[0].ip_address
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