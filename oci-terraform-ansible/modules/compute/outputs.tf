output "bastion_public_ip" {
  description = "The public IP address of the bastion host"
  value       = oci_core_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "The private IP address of the bastion host"
  value       = oci_core_instance.bastion.private_ip
}

output "bastion_reserved_private_ip" {
  description = "The reserved private IP address of the bastion host"
  value       = oci_core_private_ip.bastion_private_ip.ip_address
}

output "bastion_reserved_private_ip_id" {
  description = "The OCID of the bastion's reserved private IP"
  value       = oci_core_private_ip.bastion_private_ip.id
}

output "private_instance_private_ip" {
  description = "The private IP address of the private instance"
  value       = oci_core_instance.private_instance.private_ip
}

output "private_instance_reserved_private_ip" {
  description = "The reserved private IP address of the private instance"
  value       = oci_core_private_ip.private_instance_private_ip.ip_address
}

output "private_instance_reserved_private_ip_id" {
  description = "The OCID of the private instance's reserved private IP"
  value       = oci_core_private_ip.private_instance_private_ip.id
}

output "private_instance_secondary_private_ip" {
  description = "The private IP address of the secondary private instance"
  value       = var.create_second_instance ? oci_core_instance.private_instance_secondary[0].private_ip : null
}

output "private_instance_secondary_reserved_private_ip" {
  description = "The reserved private IP address of the secondary private instance"
  value       = var.create_second_instance ? oci_core_private_ip.private_instance_secondary_private_ip[0].ip_address : null
}

output "private_instance_secondary_reserved_private_ip_id" {
  description = "The OCID of the secondary private instance's reserved private IP"
  value       = var.create_second_instance ? oci_core_private_ip.private_instance_secondary_private_ip[0].id : null
}

output "bastion_id" {
  description = "The OCID of the bastion instance"
  value       = oci_core_instance.bastion.id
}

output "private_instance_id" {
  description = "The OCID of the private instance"
  value       = oci_core_instance.private_instance.id
}

output "private_instance_secondary_id" {
  description = "The OCID of the secondary private instance"
  value       = var.create_second_instance ? oci_core_instance.private_instance_secondary[0].id : null
}