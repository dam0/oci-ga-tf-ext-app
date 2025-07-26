# Private Compute Module Outputs

output "instance_ids" {
  description = "The OCIDs of the private instances"
  value       = oci_core_instance.private_instance[*].id
}

output "instance_display_names" {
  description = "The display names of the private instances"
  value       = oci_core_instance.private_instance[*].display_name
}

output "private_ips" {
  description = "The private IP addresses of the instances"
  value       = oci_core_instance.private_instance[*].private_ip
}

output "reserved_private_ips" {
  description = "The reserved private IP addresses (if created)"
  value       = var.create_reserved_ips ? oci_core_private_ip.private_instance_private_ip[*].ip_address : []
}

output "reserved_private_ip_ids" {
  description = "The OCIDs of the reserved private IPs (if created)"
  value       = var.create_reserved_ips ? oci_core_private_ip.private_instance_private_ip[*].id : []
}

output "primary_vnic_ids" {
  description = "The OCIDs of the primary VNICs"
  value       = [for i in range(var.instance_count) : data.oci_core_vnic_attachments.private_instance_vnic_attachments[i].vnic_attachments[0].vnic_id]
}

# Data source to get VNIC attachments for each instance
data "oci_core_vnic_attachments" "private_instance_vnic_attachments" {
  count               = var.instance_count
  compartment_id      = var.compartment_id
  instance_id         = oci_core_instance.private_instance[count.index].id
}

output "secondary_vnic_ids" {
  description = "The OCIDs of the secondary VNICs (if created)"
  value       = var.create_reserved_ips ? oci_core_vnic_attachment.private_instance_vnic_attachment[*].vnic_id : []
}