# Network Module Outputs

output "vcn_id" {
  description = "The OCID of the VCN"
  value       = oci_core_vcn.vcn.id
}

output "vcn_cidr_block" {
  description = "The CIDR block of the VCN"
  value       = oci_core_vcn.vcn.cidr_block
}

output "public_subnet_id" {
  description = "The OCID of the public subnet"
  value       = oci_core_subnet.public_subnet.id
}

output "private_subnet_id" {
  description = "The OCID of the private subnet"
  value       = oci_core_subnet.private_subnet.id
}

output "public_subnet_cidr" {
  description = "The CIDR block of the public subnet"
  value       = oci_core_subnet.public_subnet.cidr_block
}

output "private_subnet_cidr" {
  description = "The CIDR block of the private subnet"
  value       = oci_core_subnet.private_subnet.cidr_block
}

output "internet_gateway_id" {
  description = "The OCID of the Internet Gateway"
  value       = oci_core_internet_gateway.internet_gateway.id
}

output "nat_gateway_id" {
  description = "The OCID of the NAT Gateway"
  value       = oci_core_nat_gateway.nat_gateway.id
}

output "public_route_table_id" {
  description = "The OCID of the public route table"
  value       = oci_core_route_table.public_route_table.id
}

output "private_route_table_id" {
  description = "The OCID of the private route table"
  value       = oci_core_route_table.private_route_table.id
}

output "public_security_list_id" {
  description = "The OCID of the public security list"
  value       = oci_core_security_list.public_security_list.id
}

output "private_security_list_id" {
  description = "The OCID of the private security list"
  value       = oci_core_security_list.private_security_list.id
}

# Network Security Group Outputs
output "bastion_nsg_id" {
  description = "The OCID of the bastion NSG"
  value       = oci_core_network_security_group.bastion_nsg.id
}

output "private_compute_nsg_id" {
  description = "The OCID of the private compute NSG"
  value       = oci_core_network_security_group.private_compute_nsg.id
}

output "load_balancer_nsg_id" {
  description = "The OCID of the load balancer NSG"
  value       = oci_core_network_security_group.load_balancer_nsg.id
}