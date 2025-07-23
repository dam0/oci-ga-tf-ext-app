# Network outputs
output "vcn_id" {
  description = "The OCID of the VCN"
  value       = module.network.vcn_id
}

output "vcn_cidr" {
  description = "The CIDR block of the VCN"
  value       = module.network.vcn_cidr_block
}

output "public_subnet_id" {
  description = "The OCID of the public subnet"
  value       = module.network.public_subnet_id
}

output "private_subnet_id" {
  description = "The OCID of the private subnet"
  value       = module.network.private_subnet_id
}

output "public_subnet_cidr" {
  description = "The CIDR block of the public subnet"
  value       = module.network.public_subnet_cidr
}

output "private_subnet_cidr" {
  description = "The CIDR block of the private subnet"
  value       = module.network.private_subnet_cidr
}

# Compute outputs
output "bastion_public_ip" {
  description = "The public IP address of the bastion host"
  value       = module.compute.bastion_public_ip
}

output "bastion_private_ip" {
  description = "The private IP address of the bastion host"
  value       = module.compute.bastion_private_ip
}

output "bastion_reserved_private_ip" {
  description = "The reserved private IP address for the bastion"
  value       = module.compute.bastion_reserved_private_ip
}

output "bastion_id" {
  description = "The OCID of the bastion host"
  value       = module.compute.bastion_id
}

output "bastion_private_ip_id" {
  description = "The OCID of the bastion's reserved private IP"
  value       = module.compute.bastion_reserved_private_ip_id
}

output "private_instance_private_ip" {
  description = "The private IP address of the private instance"
  value       = module.compute.private_instance_private_ip
}

output "private_instance_reserved_private_ip" {
  description = "The reserved private IP address for the private instance"
  value       = module.compute.private_instance_reserved_private_ip
}

output "private_instance_id" {
  description = "The OCID of the private instance"
  value       = module.compute.private_instance_id
}

output "private_instance_private_ip_id" {
  description = "The OCID of the private instance's reserved private IP"
  value       = module.compute.private_instance_reserved_private_ip_id
}

output "second_private_instance_private_ip" {
  description = "The private IP address of the second private instance (if created)"
  value       = module.compute.private_instance_secondary_private_ip
}

output "second_private_instance_reserved_private_ip" {
  description = "The reserved private IP address for the second private instance (if created)"
  value       = module.compute.private_instance_secondary_reserved_private_ip
}

output "second_private_instance_id" {
  description = "The OCID of the second private instance (if created)"
  value       = module.compute.private_instance_secondary_id
}

output "second_private_instance_private_ip_id" {
  description = "The OCID of the second private instance's reserved private IP (if created)"
  value       = module.compute.private_instance_secondary_reserved_private_ip_id
}