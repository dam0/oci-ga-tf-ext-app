# Network Module - Creates VCN, subnets, gateways, and security groups

# Create a VCN
resource "oci_core_vcn" "vcn" {
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-vcn"
  dns_label      = var.dns_label
}

# Create an Internet Gateway
resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-internet-gateway"
  vcn_id         = oci_core_vcn.vcn.id
}

# Create a NAT Gateway for the private subnet
resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-nat-gateway"
  vcn_id         = oci_core_vcn.vcn.id
}

# Create a Route Table for the public subnet
resource "oci_core_route_table" "public_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.name_prefix}-public-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

# Create a Route Table for the private subnet
resource "oci_core_route_table" "private_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.name_prefix}-private-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gateway.id
  }
}

# Create a Security List for the public subnet
resource "oci_core_security_list" "public_security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.name_prefix}-public-security-list"

  # Allow SSH traffic from allowed CIDR blocks
  dynamic "ingress_security_rules" {
    for_each = var.allowed_ssh_cidr
    content {
      protocol  = "6" # TCP
      source    = ingress_security_rules.value
      stateless = false

      tcp_options {
        min = 22
        max = 22
      }
    }
  }

  # Allow HTTP traffic from allowed IPv4 CIDR blocks (optional)
  dynamic "ingress_security_rules" {
    for_each = var.allow_http ? var.allowed_ipv4_cidr : []
    content {
      protocol  = "6" # TCP
      source    = ingress_security_rules.value
      stateless = false

      tcp_options {
        min = 80
        max = 80
      }
    }
  }

  # Allow HTTP traffic from allowed IPv6 CIDR blocks (optional)
  dynamic "ingress_security_rules" {
    for_each = var.allow_http ? var.allowed_ipv6_cidr : []
    content {
      protocol  = "6" # TCP
      source    = ingress_security_rules.value
      stateless = false
      source_type = "CIDR_BLOCK"

      tcp_options {
        min = 80
        max = 80
      }
    }
  }

  # Allow HTTPS traffic from allowed IPv4 CIDR blocks (optional)
  dynamic "ingress_security_rules" {
    for_each = var.allow_https ? var.allowed_ipv4_cidr : []
    content {
      protocol  = "6" # TCP
      source    = ingress_security_rules.value
      stateless = false

      tcp_options {
        min = 443
        max = 443
      }
    }
  }

  # Allow HTTPS traffic from allowed IPv6 CIDR blocks (optional)
  dynamic "ingress_security_rules" {
    for_each = var.allow_https ? var.allowed_ipv6_cidr : []
    content {
      protocol  = "6" # TCP
      source    = ingress_security_rules.value
      stateless = false
      source_type = "CIDR_BLOCK"

      tcp_options {
        min = 443
        max = 443
      }
    }
  }

  # Allow all outbound traffic
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
  }
}

# Create a Security List for the private subnet
resource "oci_core_security_list" "private_security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.name_prefix}-private-security-list"

  # Allow SSH traffic from the public subnet only
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = var.public_subnet_cidr
    stateless = false

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Allow application traffic from public subnet (Tomcat, ORDS)
  dynamic "ingress_security_rules" {
    for_each = var.app_ports
    content {
      protocol  = "6" # TCP
      source    = var.public_subnet_cidr
      stateless = false

      tcp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
      }
    }
  }

  # Allow all outbound traffic
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
  }
}

# Create a public subnet for the bastion
resource "oci_core_subnet" "public_subnet" {
  cidr_block        = var.public_subnet_cidr
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.vcn.id
  display_name      = "${var.name_prefix}-public-subnet"
  route_table_id    = oci_core_route_table.public_route_table.id
  security_list_ids = [oci_core_security_list.public_security_list.id]
  dns_label         = "public"
}

# Create a private subnet for the private instances
resource "oci_core_subnet" "private_subnet" {
  cidr_block                 = var.private_subnet_cidr
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  display_name               = "${var.name_prefix}-private-subnet"
  route_table_id             = oci_core_route_table.private_route_table.id
  security_list_ids          = [oci_core_security_list.private_security_list.id]
  dns_label                  = "private"
  prohibit_public_ip_on_vnic = true
}

# Network Security Groups for granular instance-level security
# NSG for Bastion Host
resource "oci_core_network_security_group" "bastion_nsg" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.name_prefix}-bastion-nsg"
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# NSG Rules for Bastion Host
resource "oci_core_network_security_group_security_rule" "bastion_ssh_ingress" {
  for_each = toset(var.allowed_ssh_cidr)
  
  network_security_group_id = oci_core_network_security_group.bastion_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = each.value
  source_type              = "CIDR_BLOCK"
  stateless                = false
  
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
  
  description = "Allow SSH access from ${each.value}"
}

resource "oci_core_network_security_group_security_rule" "bastion_egress_all" {
  network_security_group_id = oci_core_network_security_group.bastion_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type         = "CIDR_BLOCK"
  stateless                = false
  
  description = "Allow all outbound traffic"
}

# NSG for Private Compute Instances
resource "oci_core_network_security_group" "private_compute_nsg" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.name_prefix}-private-compute-nsg"
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# NSG Rules for Private Compute Instances
resource "oci_core_network_security_group_security_rule" "private_ssh_from_bastion" {
  network_security_group_id = oci_core_network_security_group.private_compute_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = oci_core_network_security_group.bastion_nsg.id
  source_type              = "NETWORK_SECURITY_GROUP"
  stateless                = false
  
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
  
  description = "Allow SSH access from bastion host"
}

# Allow application ports from load balancer subnet (CIDR-based for broader compatibility)
resource "oci_core_network_security_group_security_rule" "private_app_ports_cidr" {
  for_each = toset([for port in var.app_ports : tostring(port)])
  
  network_security_group_id = oci_core_network_security_group.private_compute_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = var.public_subnet_cidr
  source_type              = "CIDR_BLOCK"
  stateless                = false
  
  tcp_options {
    destination_port_range {
      min = tonumber(each.value)
      max = tonumber(each.value)
    }
  }
  
  description = "Allow application traffic on port ${each.value} from load balancer subnet"
}

# Allow application ports from load balancer NSG (NSG-to-NSG for enhanced security)
resource "oci_core_network_security_group_security_rule" "private_app_ports_from_lb_nsg" {
  for_each = toset([for port in var.app_ports : tostring(port)])
  
  network_security_group_id = oci_core_network_security_group.private_compute_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = oci_core_network_security_group.load_balancer_nsg.id
  source_type              = "NETWORK_SECURITY_GROUP"
  stateless                = false
  
  tcp_options {
    destination_port_range {
      min = tonumber(each.value)
      max = tonumber(each.value)
    }
  }
  
  description = "Allow application traffic on port ${each.value} from load balancer NSG"
}

resource "oci_core_network_security_group_security_rule" "private_egress_all" {
  network_security_group_id = oci_core_network_security_group.private_compute_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type         = "CIDR_BLOCK"
  stateless                = false
  
  description = "Allow all outbound traffic"
}

# NSG for Load Balancer
resource "oci_core_network_security_group" "load_balancer_nsg" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.name_prefix}-load-balancer-nsg"
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# NSG Rules for Load Balancer
resource "oci_core_network_security_group_security_rule" "lb_http_ingress" {
  for_each = var.allow_http ? toset(concat(var.allowed_ipv4_cidr, var.allowed_ipv6_cidr)) : toset([])
  
  network_security_group_id = oci_core_network_security_group.load_balancer_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = each.value
  source_type              = "CIDR_BLOCK"
  stateless                = false
  
  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
  
  description = "Allow HTTP traffic from ${each.value}"
}

resource "oci_core_network_security_group_security_rule" "lb_https_ingress" {
  for_each = var.allow_https ? toset(concat(var.allowed_ipv4_cidr, var.allowed_ipv6_cidr)) : toset([])
  
  network_security_group_id = oci_core_network_security_group.load_balancer_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = each.value
  source_type              = "CIDR_BLOCK"
  stateless                = false
  
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
  
  description = "Allow HTTPS traffic from ${each.value}"
}

# Load balancer egress to private subnet (CIDR-based for broader compatibility)
resource "oci_core_network_security_group_security_rule" "lb_egress_to_private_cidr" {
  for_each = toset([for port in var.app_ports : tostring(port)])
  
  network_security_group_id = oci_core_network_security_group.load_balancer_nsg.id
  direction                 = "EGRESS"
  protocol                  = "6" # TCP
  destination               = var.private_subnet_cidr
  destination_type         = "CIDR_BLOCK"
  stateless                = false
  
  tcp_options {
    destination_port_range {
      min = tonumber(each.value)
      max = tonumber(each.value)
    }
  }
  
  description = "Allow outbound traffic to private subnet on port ${each.value}"
}

# Load balancer egress to private compute NSG (NSG-to-NSG for enhanced security)
resource "oci_core_network_security_group_security_rule" "lb_egress_to_private_nsg" {
  for_each = toset([for port in var.app_ports : tostring(port)])
  
  network_security_group_id = oci_core_network_security_group.load_balancer_nsg.id
  direction                 = "EGRESS"
  protocol                  = "6" # TCP
  destination               = oci_core_network_security_group.private_compute_nsg.id
  destination_type         = "NETWORK_SECURITY_GROUP"
  stateless                = false
  
  tcp_options {
    destination_port_range {
      min = tonumber(each.value)
      max = tonumber(each.value)
    }
  }
  
  description = "Allow outbound traffic to private compute NSG on port ${each.value}"
}