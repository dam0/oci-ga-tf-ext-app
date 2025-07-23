# Bastion Module Outputs

output "instance_id" {
  description = "The OCID of the bastion instance"
  value       = oci_core_instance.bastion.id
}

output "instance_display_name" {
  description = "The display name of the bastion instance"
  value       = oci_core_instance.bastion.display_name
}

output "public_ip" {
  description = "The public IP address of the bastion instance"
  value       = oci_core_instance.bastion.public_ip
}

output "private_ip" {
  description = "The private IP address of the bastion instance"
  value       = oci_core_instance.bastion.private_ip
}

output "reserved_private_ip" {
  description = "The reserved private IP address (if created)"
  value       = var.create_reserved_ip ? oci_core_private_ip.bastion_private_ip[0].ip_address : null
}

output "reserved_private_ip_id" {
  description = "The OCID of the reserved private IP (if created)"
  value       = var.create_reserved_ip ? oci_core_private_ip.bastion_private_ip[0].id : null
}

output "vnic_id" {
  description = "The OCID of the primary VNIC"
  value       = oci_core_instance.bastion.create_vnic_details[0].vnic_id
}

output "secondary_vnic_id" {
  description = "The OCID of the secondary VNIC (if created)"
  value       = var.create_reserved_ip ? oci_core_vnic_attachment.bastion_vnic_attachment[0].vnic_id : null
}