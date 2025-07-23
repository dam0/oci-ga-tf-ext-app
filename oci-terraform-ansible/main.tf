# Main Terraform configuration file

# Network Module - Creates VCN, subnets, gateways, and security lists
module "network" {
  source = "./modules/network"

  compartment_id = var.compartment_id
  vcn_cidr       = var.vcn_cidr
  
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  
  # Use name_prefix for consistent naming
  name_prefix = "test-ext"
  dns_label   = "testextvcn"
  
  # Optional security settings
  allow_http  = true
  allow_https = true
  app_ports   = [8080, 8443, 9090] # Tomcat and ORDS ports
}

# Compute Module - Creates instances with detachable private IPs
module "compute" {
  source = "./modules/compute"
  
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  name_prefix         = "test-ext"
  
  # Instance configuration
  instance_shape     = var.instance_shape
  instance_image_ocid = var.instance_image_ocid
  ssh_public_key     = var.ssh_public_key
  
  # Network references
  public_subnet_id   = module.network.public_subnet_id
  private_subnet_id  = module.network.private_subnet_id
  public_subnet_cidr = module.network.public_subnet_cidr
  private_subnet_cidr = module.network.private_subnet_cidr
  
  # Instance sizing
  bastion_memory_in_gbs = 16
  bastion_ocpus = 1
  private_instance_memory_in_gbs = 16
  private_instance_ocpus = 2
  
  # Private IP configuration
  bastion_private_ip_host_num = 10
  private_instance_ip_host_num = 10
  secondary_instance_ip_host_num = 11
  
  # Optional second instance
  create_second_instance = var.create_second_instance
  
  # Explicit dependency on network module
  depends_on = [module.network]
}

# Ansible Module - Provisions instances using Ansible
module "ansible" {
  source = "./modules/ansible"
  
  # Instance references
  bastion_id = module.compute.bastion_id
  private_instance_id = module.compute.private_instance_id
  private_instance_secondary_id = module.compute.private_instance_secondary_id
  create_second_instance = var.create_second_instance
  
  # IP addresses for Ansible inventory
  bastion_public_ip = module.compute.bastion_public_ip
  private_instance_private_ip = module.compute.private_instance_private_ip
  private_instance_secondary_private_ip = module.compute.private_instance_secondary_private_ip
  
  # Ansible configuration
  private_key_path = var.private_key_path
  wait_time_seconds = 120
  inventory_script_path = "./generate_inventory.sh"
  ansible_dir = "ansible"
  inventory_file = "inventory/hosts.ini"
  playbook_file = "provision.yml"
  ansible_limit = "--limit private_instances"
  
  # Explicit dependency on compute module
  depends_on = [module.compute]
}