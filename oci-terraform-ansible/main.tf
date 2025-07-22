# Create a VCN
resource "oci_core_vcn" "vcn" {
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_id
  display_name   = "terraform-vcn"
  dns_label      = "terraformvcn"
}

# Create an Internet Gateway
resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_id
  display_name   = "terraform-internet-gateway"
  vcn_id         = oci_core_vcn.vcn.id
}

# Create a NAT Gateway for the private subnet
resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = var.compartment_id
  display_name   = "terraform-nat-gateway"
  vcn_id         = oci_core_vcn.vcn.id
}

# Create a Route Table for the public subnet
resource "oci_core_route_table" "public_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "terraform-public-route-table"

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
  display_name   = "terraform-private-route-table"

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
  display_name   = "terraform-public-security-list"

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
  display_name   = "terraform-private-security-list"

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
  display_name      = "terraform-public-subnet"
  route_table_id    = oci_core_route_table.public_route_table.id
  security_list_ids = [oci_core_security_list.public_security_list.id]
  dns_label         = "public"
}

# Create a private subnet for the private instance
resource "oci_core_subnet" "private_subnet" {
  cidr_block                 = var.private_subnet_cidr
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  display_name               = "terraform-private-subnet"
  route_table_id             = oci_core_route_table.private_route_table.id
  security_list_ids          = [oci_core_security_list.private_security_list.id]
  dns_label                  = "private"
  prohibit_public_ip_on_vnic = true
}

# Create a bastion host in the public subnet
resource "oci_core_instance" "bastion" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "terraform-bastion"
  shape               = var.instance_shape

  create_vnic_details {
    subnet_id        = oci_core_subnet.public_subnet.id
    display_name     = "terraform-bastion-vnic"
    assign_public_ip = true
    hostname_label   = "bastion"
  }

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

# Create a reserved private IP for the bastion that can be detached and reused
resource "oci_core_private_ip" "bastion_private_ip" {
  display_name   = "terraform-bastion-private-ip"
  ip_address     = cidrhost(var.public_subnet_cidr, 10) # Assign a specific IP in the public subnet
  vnic_id        = oci_core_vnic_attachment.bastion_vnic_attachment.vnic_id
  hostname_label = "bastion-private-ip"
  
  # This ensures the private IP is detached before the VNIC is destroyed
  lifecycle {
    create_before_destroy = true
  }
  
  # Add explicit dependency to control destroy order
  depends_on = [oci_core_vnic_attachment.bastion_vnic_attachment]
}

# Create a VNIC attachment for the bastion's reserved private IP
resource "oci_core_vnic_attachment" "bastion_vnic_attachment" {
  instance_id  = oci_core_instance.bastion.id
  display_name = "terraform-bastion-secondary-vnic"

  create_vnic_details {
    subnet_id              = oci_core_subnet.public_subnet.id
    display_name           = "terraform-bastion-secondary-vnic"
    assign_public_ip       = false
    skip_source_dest_check = false
  }
  
  # This ensures proper destroy order
  lifecycle {
    create_before_destroy = true
  }
}

# This resource ensures the bastion's private IP is detached before the VNIC is destroyed
resource "null_resource" "detach_bastion_private_ip" {
  # Only run this on destroy
  triggers = {
    private_ip_id = oci_core_private_ip.bastion_private_ip.id
  }

  # This provisioner will run before the resource is destroyed
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Detaching bastion private IP ${self.triggers.private_ip_id} before VNIC destruction"
      # Uncomment the line below when running in an environment with OCI CLI configured
      # oci network private-ip update --private-ip-id ${self.triggers.private_ip_id} --vnic-id null || true
    EOT
  }

  depends_on = [oci_core_private_ip.bastion_private_ip]
}

# Create a private instance in the private subnet
resource "oci_core_instance" "private_instance" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "terraform-private-instance"
  shape               = var.instance_shape

  create_vnic_details {
    subnet_id        = oci_core_subnet.private_subnet.id
    display_name     = "terraform-private-instance-vnic"
    assign_public_ip = false
    hostname_label   = "private"
  }

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

# Create a reserved private IP for the private instance that can be detached and reused
resource "oci_core_private_ip" "private_instance_private_ip" {
  display_name   = "terraform-private-instance-private-ip"
  ip_address     = cidrhost(var.private_subnet_cidr, 10) # Assign a specific IP in the private subnet
  vnic_id        = oci_core_vnic_attachment.private_instance_vnic_attachment.vnic_id
  hostname_label = "private-instance-private-ip"
  
  # This ensures the private IP is detached before the VNIC is destroyed
  lifecycle {
    create_before_destroy = true
  }
  
  # Add explicit dependency to control destroy order
  depends_on = [oci_core_vnic_attachment.private_instance_vnic_attachment]
}

# Create a VNIC attachment for the private instance's reserved private IP
resource "oci_core_vnic_attachment" "private_instance_vnic_attachment" {
  instance_id  = oci_core_instance.private_instance.id
  display_name = "terraform-private-instance-secondary-vnic"

  create_vnic_details {
    subnet_id              = oci_core_subnet.private_subnet.id
    display_name           = "terraform-private-instance-secondary-vnic"
    assign_public_ip       = false
    skip_source_dest_check = false
  }
  
  # This ensures proper destroy order
  lifecycle {
    create_before_destroy = true
  }
}

# This resource ensures the private instance's private IP is detached before the VNIC is destroyed
resource "null_resource" "detach_private_instance_private_ip" {
  # Only run this on destroy
  triggers = {
    private_ip_id = oci_core_private_ip.private_instance_private_ip.id
  }

  # This provisioner will run before the resource is destroyed
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Detaching private instance private IP ${self.triggers.private_ip_id} before VNIC destruction"
      # Uncomment the line below when running in an environment with OCI CLI configured
      # oci network private-ip update --private-ip-id ${self.triggers.private_ip_id} --vnic-id null || true
    EOT
  }

  depends_on = [oci_core_private_ip.private_instance_private_ip]
}

# Create a second private instance if requested
resource "oci_core_instance" "private_instance_secondary" {
  count               = var.create_second_instance ? 1 : 0
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "terraform-private-instance-secondary"
  shape               = var.instance_shape

  create_vnic_details {
    subnet_id        = oci_core_subnet.private_subnet.id
    display_name     = "terraform-private-instance-secondary-vnic"
    assign_public_ip = false
    hostname_label   = "private2"
  }

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

# Create a reserved private IP for the second private instance that can be detached and reused
resource "oci_core_private_ip" "private_instance_secondary_private_ip" {
  count          = var.create_second_instance ? 1 : 0
  display_name   = "terraform-private-instance-secondary-private-ip"
  ip_address     = cidrhost(var.private_subnet_cidr, 11) # Assign a different specific IP in the private subnet
  vnic_id        = oci_core_vnic_attachment.private_instance_secondary_vnic_attachment[0].vnic_id
  hostname_label = "private-instance-secondary-private-ip"
  
  # This ensures the private IP is detached before the VNIC is destroyed
  lifecycle {
    create_before_destroy = true
  }
  
  # Add explicit dependency to control destroy order
  depends_on = [oci_core_vnic_attachment.private_instance_secondary_vnic_attachment]
}

# Create a VNIC attachment for the second private instance
resource "oci_core_vnic_attachment" "private_instance_secondary_vnic_attachment" {
  count        = var.create_second_instance ? 1 : 0
  instance_id  = oci_core_instance.private_instance_secondary[0].id
  display_name = "terraform-private-instance-secondary-vnic-attachment"

  create_vnic_details {
    subnet_id              = oci_core_subnet.private_subnet.id
    display_name           = "terraform-private-instance-secondary-secondary-vnic"
    assign_public_ip       = false
    skip_source_dest_check = false
  }
  
  # This ensures proper destroy order
  lifecycle {
    create_before_destroy = true
  }
}

# This resource ensures the second private instance's private IP is detached before the VNIC is destroyed
resource "null_resource" "detach_private_instance_secondary_private_ip" {
  count = var.create_second_instance ? 1 : 0
  
  # Only run this on destroy
  triggers = {
    private_ip_id = oci_core_private_ip.private_instance_secondary_private_ip[0].id
  }

  # This provisioner will run before the resource is destroyed
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Detaching second private instance private IP ${self.triggers.private_ip_id} before VNIC destruction"
      # Uncomment the line below when running in an environment with OCI CLI configured
      # oci network private-ip update --private-ip-id ${self.triggers.private_ip_id} --vnic-id null || true
    EOT
  }

  depends_on = [oci_core_private_ip.private_instance_secondary_private_ip]
}

# Null resource to run Ansible provisioning after Terraform completes
resource "null_resource" "ansible_provisioning" {
  # Only run when instances are created or updated
  triggers = {
    bastion_id = oci_core_instance.bastion.id
    private_instance_id = oci_core_instance.private_instance.id
    second_private_instance_id = var.create_second_instance ? oci_core_instance.private_instance_secondary[0].id : "none"
  }

  # Generate Ansible inventory from Terraform outputs
  provisioner "local-exec" {
    command = <<-EOT
      # Wait for instances to be fully initialized
      sleep 60
      
      # Export SSH key path (update this with your actual SSH key path)
      export SSH_PRIVATE_KEY_PATH=${var.private_key_path}
      
      # Generate Ansible inventory
      ./generate_inventory.sh
      
      # Run Ansible playbook
      cd ansible && ansible-playbook -i inventory/hosts.ini provision.yml
    EOT
  }

  depends_on = [
    oci_core_instance.bastion,
    oci_core_instance.private_instance,
    oci_core_instance.private_instance_secondary
  ]
}