# Modular Terraform Outputs for OCI Infrastructure

# Network Outputs
output "vcn_id" {
  description = "The OCID of the VCN"
  value       = module.network.vcn_id
}

output "public_subnet_id" {
  description = "The OCID of the public subnet"
  value       = module.network.public_subnet_id
}

output "private_subnet_id" {
  description = "The OCID of the private subnet"
  value       = module.network.private_subnet_id
}

# Bastion Outputs
output "bastion_instance_id" {
  description = "The OCID of the bastion instance"
  value       = module.bastion.instance_id
}

output "bastion_public_ip" {
  description = "The public IP address of the bastion instance"
  value       = module.bastion.public_ip
}

output "bastion_private_ip" {
  description = "The private IP address of the bastion instance"
  value       = module.bastion.private_ip
}

output "bastion_reserved_private_ip" {
  description = "The reserved private IP address of the bastion (if created)"
  value       = module.bastion.reserved_private_ip
}

# Private Instance Outputs
output "private_instance_ids" {
  description = "The OCIDs of the private instances"
  value       = module.private_compute.instance_ids
}

output "private_instance_display_names" {
  description = "The display names of the private instances"
  value       = module.private_compute.instance_display_names
}

output "private_instance_private_ips" {
  description = "The private IP addresses of the private instances"
  value       = module.private_compute.private_ips
}

output "private_instance_reserved_private_ips" {
  description = "The reserved private IP addresses of the private instances (if created)"
  value       = module.private_compute.reserved_private_ips
}

# SSH Connection Information
output "ssh_connection_info" {
  description = "SSH connection information"
  value = {
    bastion_ssh_command = "ssh -i ${var.private_key_path} opc@${module.bastion.public_ip}"
    private_instance_ssh_commands = [
      for i, ip in module.private_compute.private_ips :
      "ssh -i ${var.private_key_path} -o ProxyCommand='ssh -W %h:%p -i ${var.private_key_path} opc@${module.bastion.public_ip}' opc@${ip}"
    ]
  }
}

# Load Balancer Outputs
output "load_balancer_id" {
  description = "The OCID of the load balancer"
  value       = module.load_balancer.load_balancer_id
}

output "load_balancer_ip" {
  description = "The IP address of the load balancer"
  value       = module.load_balancer.load_balancer_ip
}

output "load_balancer_http_listener" {
  description = "The name of the HTTP listener"
  value       = module.load_balancer.http_listener_name
}

output "load_balancer_https_listener" {
  description = "The name of the HTTPS listener"
  value       = module.load_balancer.https_listener_name
}

output "load_balancer_backend_set" {
  description = "The name of the backend set"
  value       = module.load_balancer.backend_set_name
}

# WAF Outputs
output "waf_policy_id" {
  description = "The OCID of the WAF policy (if enabled)"
  value       = module.load_balancer.waf_policy_id
}

output "waf_id" {
  description = "The OCID of the WAF (if enabled)"
  value       = module.load_balancer.waf_id
}

output "waf_enabled" {
  description = "Whether WAF is enabled"
  value       = module.load_balancer.waf_enabled
}

output "waf_allowed_paths" {
  description = "The paths allowed through the WAF"
  value       = module.load_balancer.waf_allowed_paths
}

# Network Security Group Outputs
output "bastion_nsg_id" {
  description = "The OCID of the bastion NSG"
  value       = module.network.bastion_nsg_id
}

output "private_compute_nsg_id" {
  description = "The OCID of the private compute NSG"
  value       = module.network.private_compute_nsg_id
}

output "load_balancer_nsg_id" {
  description = "The OCID of the load balancer NSG"
  value       = module.network.load_balancer_nsg_id
}

# Ansible Inventory Information
output "ansible_inventory_info" {
  description = "Information for Ansible inventory"
  value = {
    bastion = {
      public_ip  = module.bastion.public_ip
      private_ip = module.bastion.private_ip
    }
    private_instances = [
      for i, ip in module.private_compute.private_ips : {
        name       = module.private_compute.instance_display_names[i]
        private_ip = ip
        reserved_ip = length(module.private_compute.reserved_private_ips) > i ? module.private_compute.reserved_private_ips[i] : null
      }
    ]
    load_balancer = {
      ip_address = module.load_balancer.load_balancer_ip
      http_url   = "http://${module.load_balancer.load_balancer_ip}"
      https_url  = "https://${module.load_balancer.load_balancer_ip}"
    }
  }
}