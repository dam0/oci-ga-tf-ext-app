# Modular Terraform Configuration for OCI Infrastructure

# Network Module - Creates VCN, subnets, gateways, and security groups
module "network" {
  source = "./modules/network"

  compartment_id        = var.compartment_id
  vcn_cidr             = var.vcn_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidr  = var.private_subnet_cidr
  name_prefix          = var.name_prefix
  dns_label            = var.dns_label
  allow_http           = var.allow_http
  allow_https          = var.allow_https
  app_ports            = var.app_ports
  
  # IP Filtering
  allowed_ipv4_cidr    = var.allowed_ipv4_cidr
  allowed_ipv6_cidr    = var.allowed_ipv6_cidr
  allowed_ssh_cidr     = var.allowed_ssh_cidr
  
  # Tagging
  freeform_tags        = var.freeform_tags
  defined_tags         = var.defined_tags
}

# Bastion Module - Creates bastion host with reserved private IP
module "bastion" {
  source = "./modules/bastion"

  compartment_id         = var.compartment_id
  availability_domain    = var.availability_domain
  public_subnet_id       = module.network.public_subnet_id
  instance_shape         = var.instance_shape
  instance_shape_config  = var.bastion_shape_config
  instance_image_ocid    = var.instance_image_ocid
  ssh_public_key         = var.ssh_public_key
  name_prefix           = var.name_prefix
  hostname_label        = "bastion"
  create_reserved_ip    = var.create_bastion_reserved_ip
  reserved_ip_address   = var.bastion_reserved_ip_address
  user_data             = var.bastion_user_data
  nsg_ids               = [module.network.bastion_nsg_id]
  freeform_tags         = var.freeform_tags
  defined_tags          = var.defined_tags

  depends_on = [module.network]
}

# Private Compute Module - Creates private instances with reserved private IPs
module "private_compute" {
  source = "./modules/private_compute"

  compartment_id         = var.compartment_id
  availability_domain    = var.availability_domain
  private_subnet_id      = module.network.private_subnet_id
  private_subnet_cidr    = module.network.private_subnet_cidr
  instance_count         = var.private_instance_count
  instance_shape         = var.instance_shape
  instance_shape_config  = var.private_instance_shape_config
  instance_image_ocid    = var.instance_image_ocid
  ssh_public_key         = var.ssh_public_key
  name_prefix           = var.name_prefix
  hostname_label_prefix = "private"
  create_reserved_ips   = var.create_private_reserved_ips
  reserved_ip_addresses = var.private_reserved_ip_addresses
  user_data             = var.private_instance_user_data
  nsg_ids               = [module.network.private_compute_nsg_id]
  freeform_tags         = var.freeform_tags
  defined_tags          = var.defined_tags

  depends_on = [module.network]
}

# Load Balancer Module - Creates a load balancer for Tomcat instances
module "load_balancer" {
  source = "./modules/load_balancer"
  
  compartment_id = var.compartment_id
  name_prefix    = var.name_prefix
  
  # Network configuration
  subnet_ids = [module.network.public_subnet_id]
  is_private = var.lb_is_private
  
  # Backend server configuration
  backend_servers = [
    for i in range(var.private_instance_count) : {
      ip_address = module.private_compute.private_ips[i]
      backup     = false
      drain      = false
      offline    = false
      weight     = 1
    }
  ]
  
  # Certificate configuration (using the provided OCID)
  certificate_ocid = var.certificate_ocid
  
  # Load balancer configuration
  lb_shape                     = var.lb_shape
  lb_min_shape_bandwidth_mbps  = var.lb_min_bandwidth_mbps
  lb_max_shape_bandwidth_mbps  = var.lb_max_bandwidth_mbps
  
  # Tomcat configuration
  tomcat_port              = var.tomcat_port
  health_check_url_path    = var.health_check_url_path
  
  # WAF configuration
  enable_waf                           = var.enable_waf
  waf_rate_limit_requests_per_minute   = var.waf_rate_limit_requests_per_minute
  waf_allowed_paths                    = var.waf_allowed_paths
  
  # IP Filtering (used for NSG configuration)
  allowed_ipv4_cidr                    = var.allowed_ipv4_cidr
  allowed_ipv6_cidr                    = var.allowed_ipv6_cidr
  
  # Network Security Groups
  nsg_ids                              = [module.network.load_balancer_nsg_id]
  
  # Tagging
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
  
  # Explicit dependency on compute module
  depends_on = [module.private_compute]
}


# Ansible Provisioning - Run Ansible after infrastructure is created
resource "null_resource" "ansible_provisioning" {
  count = var.enable_ansible_provisioning ? 1 : 0

  triggers = {
    bastion_id = module.bastion.instance_id
    private_instance_ids = join(",", module.private_compute.instance_ids)
    network_ready = module.network.vcn_id
    load_balancer_ready = module.load_balancer.load_balancer_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for instances to be fully initialized
      sleep 120

      # Export SSH key path
      export SSH_PRIVATE_KEY_PATH=${var.private_key_path}

      # Generate Ansible inventory
      ./generate_inventory.sh

      # Run Ansible playbook
      cd ansible && ansible-playbook -i inventory/hosts.ini provision.yml --limit private_instances --private-key ${var.private_key_path} -e "ansible_user=opc ansible_ssh_common_args='-o ProxyCommand=\"ssh -W %h:%p -i ${var.private_key_path} -o StrictHostKeyChecking=no bastion\"'"
    EOT
  }

  depends_on = [
    module.bastion,
    module.private_compute,
    module.load_balancer
  ]
}