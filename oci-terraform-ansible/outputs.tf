output "bastion_public_ip" {
  description = "The public IP address of the bastion host"
  value       = oci_core_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "The reserved private IP address for the bastion"
  value       = oci_core_private_ip.bastion_private_ip.ip_address
}

output "bastion_id" {
  description = "The OCID of the bastion host"
  value       = oci_core_instance.bastion.id
}

output "bastion_vnic_id" {
  description = "The OCID of the bastion VNIC attachment"
  value       = oci_core_vnic_attachment.bastion_vnic_attachment.vnic_id
}

output "bastion_private_ip_id" {
  description = "The OCID of the bastion's reserved private IP"
  value       = oci_core_private_ip.bastion_private_ip.id
}

output "private_instance_private_ip" {
  description = "The reserved private IP address for the private instance"
  value       = oci_core_private_ip.private_instance_private_ip.ip_address
}

output "private_instance_id" {
  description = "The OCID of the private instance"
  value       = oci_core_instance.private_instance.id
}

output "private_instance_vnic_id" {
  description = "The OCID of the private instance VNIC attachment"
  value       = oci_core_vnic_attachment.private_instance_vnic_attachment.vnic_id
}

output "private_instance_private_ip_id" {
  description = "The OCID of the private instance's reserved private IP"
  value       = oci_core_private_ip.private_instance_private_ip.id
}

output "second_private_instance_id" {
  description = "The OCID of the second private instance (if created)"
  value       = var.create_second_instance ? oci_core_instance.private_instance_secondary[0].id : null
}

output "second_private_instance_vnic_id" {
  description = "The OCID of the second private instance VNIC attachment (if created)"
  value       = var.create_second_instance ? oci_core_vnic_attachment.private_instance_secondary_vnic_attachment[0].vnic_id : null
}

output "second_private_instance_private_ip" {
  description = "The reserved private IP address for the second private instance (if created)"
  value       = var.create_second_instance ? oci_core_private_ip.private_instance_secondary_private_ip[0].ip_address : null
}

output "second_private_instance_private_ip_id" {
  description = "The OCID of the second private instance's reserved private IP (if created)"
  value       = var.create_second_instance ? oci_core_private_ip.private_instance_secondary_private_ip[0].id : null
}

output "public_subnet_cidr" {
  description = "The CIDR block of the public subnet"
  value       = var.public_subnet_cidr
}

output "private_subnet_cidr" {
  description = "The CIDR block of the private subnet"
  value       = var.private_subnet_cidr
}