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

  # Allow SSH traffic from anywhere
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Allow HTTP traffic from anywhere (optional)
  dynamic "ingress_security_rules" {
    for_each = var.allow_http ? [1] : []
    content {
      protocol  = "6" # TCP
      source    = "0.0.0.0/0"
      stateless = false

      tcp_options {
        min = 80
        max = 80
      }
    }
  }

  # Allow HTTPS traffic from anywhere (optional)
  dynamic "ingress_security_rules" {
    for_each = var.allow_https ? [1] : []
    content {
      protocol  = "6" # TCP
      source    = "0.0.0.0/0"
      stateless = false

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